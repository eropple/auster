# frozen_string_literal: true
require "cri"

require "cfer/auster/cli/_shared"

module Cfer
  module Auster
    module CLI
      def self.run
        Cri::Command.define do
          name "run"
          usage "run aws-region/config-set count-or-tag"
          description "Runs this Auster step against your AWS infrastructure."

          CLI.standard_options(self)

          run do |opts, args, cmd|
            if args.length < 2
              puts cmd.help
              exit 1
            else
              CLI.repo_from_options(opts) do |repo|
                config_set = repo.config_set(args[0])
                step = repo.step_by_count_or_tag(args[1])

                step.run(config_set)
              end
            end
          end
        end
      end
    end
  end
end
