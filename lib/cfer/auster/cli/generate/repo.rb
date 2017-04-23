# frozen_string_literal: true
require "cri"

module Cfer
  module Auster
    module CLI
      def self.generate_repo
        Cri::Command.define do
          name "repo"
          usage "repo OUTPUT_PATH"
          description "Generates a new Auster plan repo."

          CLI.base_options(self)

          flag :h, :help, "show help for this command" do |_, cmd|
            puts cmd.help
            Kernel.exit 0
          end

          run do |_, _, cmd|
            raise "TODO: implement"
          end
        end
      end
    end
  end
end
