# frozen_string_literal: true

require "cfer"

module Cfer
  module Core
    class Resource
      # TODO: we need a better way to inject general helpers.

      def cfize(text, capture_regexp: nil)
        Cfer::Auster::CferHelpers.cfize(text, capture_regexp: capture_regexp)
      end
    end
  end

  module Auster
    class CloudFormationError < RuntimeError; end

    class CferEvaluator
      include Cfer::Auster::Logging::Mixin

      def initialize(path:, stack_name:, parameters:, metadata:, client_options: {}, stack_options: {})
        raise "path must be a String" unless path.is_a?(String)
        raise "path must be a directory" unless File.directory?(path)

        raise "stack_name must be a String" unless stack_name.is_a?(String)

        raise "parameters must be a Hash" unless parameters.is_a?(Hash)

        parameters[:AusterOptions] ||= {}

        @stack_name = stack_name
        @stack_options = stack_options
        @cfer_client = Cfer::Cfn::Client.new(client_options.merge(stack_name: stack_name, region: parameters[:AWSRegion]))
        @cfer_stack = Cfer::Core::Stack.new(
          stack_options.merge(
            client: @cfer_client, include_base: path, parameters: parameters,
            force_s3: !!parameters[:AusterOptions][:S3Path],
            s3_path: parameters[:AusterOptions][:S3Path]
          )
        )

        require_rb = File.join(path, "require.rb")
        parameters_rb = File.join(path, "parameters.rb")
        outputs_rb = File.join(path, "outputs.rb")

        global_helpers_dir = File.join(path, "../../../cfer-helpers")
        global_helpers = Dir["#{global_helpers_dir}/**/*.rb"].reject { |f| File.basename(f).start_with?("_") }
        helpers_dir = File.join(path, "helpers")
        helpers = Dir["#{helpers_dir}/**/*.rb"].reject { |f| File.basename(f).start_with?("_") }
        defs_dir = File.join(path, "defs")

        @cfer_stack.extend Cfer::Auster::CferHelpers
        @cfer_stack.build_from_block do
          self[:Metadata][:Auster] = metadata

          global_helpers.each do |helper_file|
            eval_file helper_file
          end

          helpers.each do |helper_file|
            eval_file helper_file
          end

          [require_rb, parameters_rb, outputs_rb].each do |file|
            f = file.gsub(path, ".")
            include_template f if File.file?(file)
          end

          Dir["#{defs_dir}/**/*.rb"].each do |def_file|
            f = def_file.gsub(path, ".")
            include_template f
          end
        end
      end

      def converge!(block: true)
        # because it isn't actually redundant...
        # rubocop:disable Style/RedundantBegin
        begin
          @cfer_stack.converge!(@stack_options)
          tail! if block
        rescue Aws::CloudFormation::Errors::ValidationError => err
          if err.message == "No updates are to be performed."
            logger.info "CloudFormation has no updates to perform."
          else
            logger.error "Error (#{err.class.name}) in converge: #{err.message}"
            raise err
          end
        end
      end

      def destroy!(block: true)
        @cfer_client.delete_stack(stack_name: @stack_name)
        tail! if block
      end

      def tail!(throw_if_failed: true)
        tail_start = DateTime.now
        has_shown_bar = false
        has_failed = false

        @cfer_client.tail(number: 0, follow: true) do |event|
          has_failed = true if event.timestamp >= tail_start && event.resource_status.include?("FAILED")
          if event.timestamp >= tail_start && !has_shown_bar
            logger.info "CFN >> ----- CURRENT RUN START -----"
            has_failed = false
            has_shown_bar = true
          end
          logger.info "CFN >> %-30s %-40s %-20s %s" % [
            event.resource_status, event.resource_type,
            event.logical_resource_id, event.resource_status_reason
          ]
        end

        raise "Operation failed. Please check the log." if has_failed && throw_if_failed
        nil
      end

      def generate_json
        JSON.pretty_generate(@cfer_stack)
      end
    end
  end
end
