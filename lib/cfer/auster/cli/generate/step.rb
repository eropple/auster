# frozen_string_literal: true
require "cri"

module Cfer
  module Auster
    module CLI
      def self.generate_step
        Cri::Command.define do
          name "step"
          usage "step ##"
          description "Generates a step in the current Auster repo."

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
