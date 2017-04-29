# frozen_string_literal: true
require "cri"

require "cfer/auster/cli/_shared"

module Cfer
  module Auster
    module CLI
      def self.tasks
        Cri::Command.define do
          name "tasks"
          usage "tasks"
          description "Prints a list of tasks available in this repo."

          CLI.standard_options(self)

          run do |opts, args, cmd|
            CLI.repo_from_options(opts) do |repo|
              repo.tasks.each { |t| puts t }
            end
          end
        end
      end
    end
  end
end
