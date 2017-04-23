# frozen_string_literal: true
require "cri"
require "logger"

module Cfer
  module Auster
    module CLI
      def self.base_options(cmd)
        cmd.instance_eval do
          flag :v, :verbose, "sets logging to DEBUG" do |_, _|
            Cfer::Auster::Logging.logger.level = Logger::DEBUG
          end
        end
      end

      def self.standard_options(cmd)
        cmd.instance_eval do
          CLI.base_options(cmd)

          flag :h, :help, "show help for this command" do |_, cmd|
            puts cmd.help
            Kernel.exit 0
          end

          option :l, :"log-level",
                 "Configures the verbosity of the Auster and Cfer loggers. (default: info)",
                 argument: :required

          option :p, :"plan-path",
                 "The path to the Auster plan repo that should be used (otherwise searches from pwd)",
                 argument: :required
        end
      end

      def self.repo_from_options(opts, &block)
        require "cfer/auster/repo"

        repo =
          if opts[:"plan-path"]
            Cfer::Auster::Repo.new(opts[:"plan-path"])
          else
            Cfer::Auster::Repo.discover_from_cwd
          end

        block.call(repo)
      end
    end
  end
end
