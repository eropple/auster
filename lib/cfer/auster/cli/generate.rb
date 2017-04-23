# frozen_string_literal: true
require "cri"

require "cfer/auster/cli/generate/repo"
require "cfer/auster/cli/generate/step"

module Cfer
  module Auster
    module CLI
      def self.generate
        ret = Cri::Command.define do
          name "generate"
          description "Encapsulates generators for Auster."

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

        ret.add_command(CLI.generate_repo)
        ret.add_command(CLI.generate_step)

        ret
      end
    end
  end
end
