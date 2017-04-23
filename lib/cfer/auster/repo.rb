# frozen_string_literal: true
module Cfer
  module Auster
    class Repo
      include Cfer::Auster::Logging::Mixin

      REPO_FILE = ".auster.yaml"
      STEP_REGEX = /(?<count>[0-9]{2})\.(?<tag>[a-z0-9][a-z0-9\-]*[a-z0-9])/
      INT_REGEX = /[0-9]+/

      attr_reader :root
      attr_reader :options

      attr_reader :steps
      attr_reader :config_sets

      attr_reader :param_validator

      def initialize(root)
        raise "root must be a String." unless root.is_a?(String)
        @root = File.expand_path(root).freeze

        logger.debug "Repo location: #{@root}"

        options_file = File.expand_path(REPO_FILE, @root)
        logger.debug "Loading options file..."
        raise "#{options_file} does not exist." unless File.file?(options_file)
        @options = YAML.load_file(options_file)

        @cfg_root = File.join(@root, "config").freeze
        raise "#{@cfg_root} does not exist." unless File.directory?(@cfg_root)
        @step_root = File.join(@root, "steps").freeze
        raise "#{@step_root} does not exist." unless File.directory?(@step_root)

        logger.debug "Enumerating steps..."
        steps = build_steps
        step_tags = steps.map(&:tag)
        step_counts = steps.map(&:count)

        raise "Multiple steps with the same tag found. Can't continue." \
          if step_tags.uniq.length != steps.length
        raise "Multiple steps with the same count found. Can't continue." \
          if step_counts.uniq.length != steps.length

        @steps = steps.map { |step| [step.count, step] }.to_h.freeze
        @steps_by_tag = steps.map { |step| [step.tag, step.count] }.to_h.freeze

        logger.debug "Enumerating config sets..."
        @config_sets = find_config_sets

        logger.debug "Loading param validator..."
        @param_validator = load_param_validator
      end

      def step_by_tag(tag)
        raise "Couldn't find a step with tag '#{tag}'." unless @steps_by_tag.key?(tag)
        @steps[@steps_by_tag[tag]]
      end

      def step_by_count(count)
        @steps[count.to_i]
      end

      def step_by_count_or_tag(value)
        if INT_REGEX.match(value)
          step_by_count(value)
        else
          step_by_tag(value)
        end
      end

      def ordered_steps
        @steps.sort.map(&:last)
      end

      def config_set(id)
        raise "Config set not found with id '#{id}'." unless @config_sets.include?(id)

        tokens = id.split("/")

        name = tokens[1]
        region = tokens[0]

        filename = File.join(@cfg_root, "#{id}.yaml")

        schema_file = File.join(@cfg_root, "schema.yaml")
        schema_file = nil unless File.file?(schema_file)

        Cfer::Auster::Config.from_file(name: name, aws_region: region,
                                       schema_file: schema_file, data_file: filename)
      end

      def nuke(config_set)
        raise "config_set must be a Cfer::Auster::Config." unless config_set.is_a?(Cfer::Auster::Config)

        logger.info "Nuking '#{config_set.full_name}'."

        ordered_steps.reverse.each { |step| step.destroy(config_set) }
      end

      private

      def build_steps
        Dir[File.join(@step_root, "*")].map do |step_dir|
          step_name = File.basename(step_dir)
          match = STEP_REGEX.match(step_name)

          if match.nil?
            logger.warn "Unrecognized directory '#{step_name}' in steps, skipping."
            nil
          else
            logger.debug "Step found: #{match[:count]}.#{match[:tag]}"
            Cfer::Auster::Step.new(repo: self, count: match[:count], tag: match[:tag], directory: step_dir)
          end
        end.reject(&:nil?)
      end

      def find_config_sets
        Dir[File.join(@cfg_root, "**/*.yaml")].map do |cfgset_file|
          if File.dirname(cfgset_file) == @cfg_root
            nil # because it's not inside an AWS region
          else
            # this could probably be cleaner.
            cfgset_file.gsub(@cfg_root, "").gsub(".yaml", "")[1..-1]
          end
        end.reject(&:nil?)
      end

      def load_param_validator
        validator_path = File.join(@cfg_root, "validator.rb")

        if File.file?(validator_path)
          validator_rb = IO.read(validator_path)
          validator = instance_eval(validator_rb, validator_path)

          raise "#{validator_path} error: must return a Cfer::Auster::ParamValidator." \
            unless validator.is_a?(Cfer::Auster::ParamValidator)

          validator
        else
          Cfer::Auster::ParamValidator.new {}
        end
      end

      class << self
        def discover_from_cwd
          require "search_up"

          repo_file = SearchUp.search(Dir.pwd, REPO_FILE) { |f| File.file?(f) }.first

          raise "No repo found (signaled by #{REPO_FILE}) from pwd to root." if repo_file.nil?

          Cfer::Auster::Repo.new File.dirname(repo_file)
        end
      end
    end
  end
end
