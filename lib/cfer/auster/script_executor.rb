require "cfer/auster/aws_utils"

module Cfer
  module Auster
    class ScriptExecutor
      attr_reader :logger

      def initialize(consts)
        raise "consts must be a Hash" unless consts.is_a?(Hash)

        vars = []
        consts.each_pair do |k, v|
          key_name = k.downcase.to_sym
          vars << key_name
          define_singleton_method(key_name) { v }
        end

        define_singleton_method(:vars) { vars }
      end

      def run(filename)
        @logger = Logger.new(Cfer::Auster::Logging.logdev)
        @logger.level = Cfer::Auster::Logging.logger.level

        basename = File.basename(filename)
        standard_formatter = Logger::Formatter.new

        logger.formatter = proc do |severity, datetime, progname, msg|
          standard_formatter.call(severity, datetime, progname, "> #{basename}: #{msg}")
        end

        instance_eval IO.read(filename), filename
      end

      private

      def exports(export_plan_id = nil)
        export_plan_id ||= plan_id

        cfn_client = Aws::CloudFormation::Client.new(region: config_set.aws_region)

        # this call isn't super fast, so we cache a little bit.
        @exports ||= {}
        @exports[export_plan_id] ||=
          AwsUtils.all_from_pager(cfn_client.list_exports, :exports).map do |cfn_export|
            tokens = cfn_export.name.split("--", 2)

            if tokens.length != 2 || tokens[0] != export_plan_id
              nil
            else
              [tokens[1].to_sym, cfn_export.value]
            end
          end.reject(&:nil?).to_h

        @exports[export_plan_id]
      end
    end
  end
end
