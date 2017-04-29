# frozen_string_literal: true
require "cri"

require "cfer/auster/cli/_shared"

module Cfer
  module Auster
    module CLI
      def self.json
        Cri::Command.define do
          name "json"
          usage "json aws-region/config-set count-or-tag"
          description "Generates the CloudFormation JSON for this step."

          CLI.standard_options(self)

          option :o, :"output-file",
                 "Saves the JSON output to a file (otherwise prints to stdout)",
                 argument: :required

          run do |opts, args, cmd|
            if args.length < 2
              puts cmd.help
              exit 1
            else
              CLI.repo_from_options(opts) do |repo|
                args = args.dup
                config_set = repo.config_set(args.shift)
                step = repo.step_by_count_or_tag(args.shift)

                ret = step.json(config_set)

                if opts[:"output-file"]
                  IO.write(opts[:"output-file"], ret)
                else
                  puts ret
                end
              end
            end
          end
        end
      end
    end
  end
end
