# frozen_string_literal: true
require "cri"

require "cfer/auster/cli/_shared"

module Cfer
  module Auster
    module CLI
      def self.nuke
        Cri::Command.define do
          extend Cfer::Auster::Logging::Mixin

          name "nuke"
          usage "nuke aws-region/config-set"
          description "Destroys ALL AWS RESOURCES related to this config set."

          CLI.standard_options(self)

          flag nil, :force, "bypasses confirmation - use with care!"

          run do |opts, args, cmd|
            if args.length < 1
              puts cmd.help
              exit 1
            else
              CLI.repo_from_options(opts) do |repo|
                config_set = repo.config_set(args[0])

                accepted = !!opts[:force]

                if !accepted && $stdin.tty?
                  $stderr.write "\n\n"
                  $stderr.write "!!! YOU ARE ABOUT TO DO SOMETHING VERY DRASTIC! !!!\n"
                  $stderr.write "You are requesting to destroy ALL STEPS of the config set '#{config_set.full_name}'.\n"
                  $stderr.write "If you are certain you wish to do this, please type CONFIRM: "

                  input = $stdin.readline.chomp

                  if input != "CONFIRM"
                    $stderr.write "\n\nInvalid input. Aborting nuke.\n\n"
                    Kernel.exit 1
                  end

                  accepted = true
                end

                unless accepted
                  logger.error "You must pass interactive confirmation or use the --force parameter to nuke."
                  Kernel.exit 1
                end

                repo.nuke(config_set)

                logger.warn "I really, really hope you meant to do that."
              end
            end
          end
        end
      end
    end
  end
end
