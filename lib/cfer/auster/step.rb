# frozen_string_literal: true

require "semantic"

module Cfer
  module Auster
    class Step
      include Cfer::Auster::Logging::Mixin

      attr_reader :repo

      attr_reader :count
      attr_reader :tag
      attr_reader :directory

      def initialize(repo:, count:, tag:, directory:)
        raise "directory '#{directory}' does not exist." unless File.directory?(directory)
        @repo = repo

        @count = count.to_i
        @tag = tag.dup.freeze

        @directory = directory.dup.freeze

        @cfer_directory = File.join(@directory, "cfer")
        raise "directory '#{@cfer_directory}' does not exist." unless File.directory?(directory)
      end

      def json(config_set)
        raise "config_set must be a Cfer::Auster::Config." unless config_set.is_a?(Cfer::Auster::Config)

        with_cfer(config_set) do |cfer|
          cfer.generate_json
        end
      end

      def cfn_stack_name(config_set)
        "#{config_set.name}-step#{count.to_s.rjust(2, '0')}"
      end

      def cfn_stack(config_set)
        cfn_client = Aws::CloudFormation::Resource.new(region: config_set.aws_region)
        cfn_client.stack(cfn_stack_name(config_set))
      end

      def cfn_data(config_set)
        stack = cfn_stack(config_set)

        if !stack.exists?
          nil
        else
          cfn_parameters = stack.parameters.map { |p| [p.parameter_key, p.parameter_value] }.to_h
          cfn_outputs = stack.outputs.map { |o| [o.output_key, o.output_value] }.to_h

          cfn_combined = cfn_parameters.merge(cfn_outputs)

          {
            inputs: cfn_parameters.symbolize_keys,
            outputs: cfn_outputs.symbolize_keys,
            combined: cfn_combined.symbolize_keys
          }
        end
      end

      def apply(config_set)
        raise "config_set must be a Cfer::Auster::Config." unless config_set.is_a?(Cfer::Auster::Config)

        with_cfer(config_set) do |cfer|
          do_on_create(config_set) unless cfn_stack(config_set).exists?
          do_pre_converge(config_set)

          logger.info "Converging Cfer stack as '#{cfn_stack_name(config_set)}'."

          opts = {
            block: true,
            role_arn: config_set.data[:AusterOptions][:ServiceRoleARN]
          }

          cfer.converge!(block: true)

          do_post_converge(config_set, cfn_data(config_set))
        end
      end

      def destroy(config_set)
        raise "config_set must be a Cfer::Auster::Config." unless config_set.is_a?(Cfer::Auster::Config)

        stack_name = cfn_stack_name(config_set)
        stack = cfn_stack(config_set)

        if !stack.exists?
          logger.warn "No underlying CloudFormation stack '#{stack_name}' exists."
        else
          logger.info "Deleting CloudFormation stack '#{stack_name}'."
          with_cfer(config_set) do |cfer|
            opts = {
              block: true,
              role_arn: config_set.data[:AusterOptions][:ServiceRoleARN]
            }

            cfer.destroy!(block: true)
          end

          do_on_destroy(config_set)
        end
      end

      private

      def do_on_create(config_set)
        run_scripts("on-create", config_set)
      end

      def do_on_destroy(config_set)
        run_scripts("on-destroy", config_set)
      end

      def do_pre_converge(config_set)
        run_scripts("pre-converge", config_set)
      end

      def do_post_converge(config_set, cfn_data)
        run_scripts("post-converge", config_set, cfn_data: cfn_data)
      end

      def with_cfer(config_set, &block)
        parameters = config_set.data
        validation_errors = repo.param_validator.validate(parameters)

        unless validation_errors.empty?
          logger.error "Config set '#{config_set.full_name}' failed to validate with the following errors:"
          validation_errors.each do |e|
            logger.error " - #{e}"
          end

          raise "Validation of config set '#{config_set.full_name}' failed during Cfer build."
        end

        cfer = CferEvaluator.new(path: @cfer_directory, stack_name: cfn_stack_name(config_set),
                                 parameters: parameters, metadata: stack_metadata)

        block.call(cfer)
      end

      def stack_metadata
        {
          Version: Semantic::Version.new(Cfer::Auster::VERSION).to_h.reject { |k, v| v.nil? }
        }
      end

      def converge_cfn(config_set)
      end

      def run_scripts(event_type, config_set, rb_vars = {})
        logger.info "Running scripts for #{event_type}"
        env_vars = config_set.env_vars_for_shell

        injected_vars = env_vars.merge(rb_vars).merge(
          repo: repo,
          step: self,
          config_set: config_set
        )

        scripts_for_event(event_type).each do |script_name|
          case File.extname(script_name)
          when ".rb"
            logger.debug "Executing #{script_name} in-process."
            Cfer::Auster::ScriptExecutor.new(injected_vars).run(script_name)
          else
            logger.debug "Executing #{script_name} through system()."
            system(env_vars, script_name)

            raise "#{script_name} failed with exit code #{$?.exitstatus}." unless $?.success?
          end
        end
      end

      def scripts_for_event(event_type)
        dir = File.join(directory, "#{event_type}.d")

        raise "#{dir} exists, but it isn't a directory.'" \
          if File.exist?(dir) && !File.directory?(dir)

        if !File.directory?(dir)
          []
        else
          Dir[File.join(dir, "*")].select { |f| File.executable?(f) }
        end
      end
    end
  end
end
