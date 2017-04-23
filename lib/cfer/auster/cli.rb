# frozen_string_literal: true
require "cri"

require "cfer/auster"
require "cfer/auster/cli/_shared"
require "cfer/auster/cli/generate"
require "cfer/auster/cli/json"
require "cfer/auster/cli/run"
require "cfer/auster/cli/destroy"
require "cfer/auster/cli/nuke"

module Cfer
  module Auster
    module CLI
      def self.root
        ret = Cri::Command.define do
          name "auster"
          description "The best way to manage CloudFormation. Ever. (We think.)"

          CLI.base_options(self)

          flag :h, :help, "show help for this command" do |_, cmd|
            puts cmd.help
            Kernel.exit 0
          end

          run do |_, _, cmd|
            puts cmd.help
            Kernel.exit 0
          end
        end

        ret.add_command(CLI.generate)
        ret.add_command(CLI.json)
        ret.add_command(CLI.run)
        ret.add_command(CLI.destroy)
        ret.add_command(CLI.nuke)

        ret
      end

      def self.execute(args)
        CLI.root.run(args)
      end
    end
  end
end
