# frozen_string_literal: true
require "cri"

require "cfer/auster/cli/_shared"

module Cfer
  module Auster
    module CLI
      def self.apply
        Cri::Command.define do
          name "apply"
          usage "apply aws-region/config-set count-or-tag"
          description "Applies this Auster step against your AWS infrastructure."

          CLI.standard_options(self)

          run do |opts, args, cmd|
            if args.length < 2
              puts cmd.help
              exit 1
            else
              CLI.repo_from_options(opts) do |repo|
                args = args.dup
                config_set = repo.config_set(args.shift)
                step = repo.step_by_count_or_tag(args.shift)

                step.apply(config_set)
              end
            end
          end
        end
      end
    end
  end
end
