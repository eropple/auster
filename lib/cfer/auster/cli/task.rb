# frozen_string_literal: true
require "cri"

require "cfer/auster/cli/_shared"

module Cfer
  module Auster
    module CLI
      def self.task
        Cri::Command.define do
          name "task"
          usage "task aws-region/config-set script-name [args]"
          description "Runs a task within the context of an Auster config set."

          CLI.standard_options(self)

          run do |opts, args, cmd|
            if args.length < 2
              puts cmd.help
              exit 1
            else
              CLI.repo_from_options(opts) do |repo|
                args = args.dup
                config_set = repo.config_set(args.shift)
                task_name = args.shift

                repo.run_task(task_name, config_set, args)
              end
            end
          end
        end
      end
    end
  end
end
