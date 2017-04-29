# frozen_string_literal: true
require "cri"
require "semantic"
require "json"

require "cfer/auster"
require "cfer/auster/cli/_shared"
require "cfer/auster/cli/generate"
require "cfer/auster/cli/json"
require "cfer/auster/cli/task"
require "cfer/auster/cli/tasks"
require "cfer/auster/cli/destroy"
require "cfer/auster/cli/apply"
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

          flag nil, :version, "show version information for this command" do |_, _|
            puts Cfer::Auster::VERSION
            Kernel.exit 0
          end
          flag nil, :"version-json", "show version information for this command in JSON" do |_, _|
            puts JSON.pretty_generate(
              Semantic::Version.new(Cfer::Auster::VERSION).to_h.reject { |_, v| v.nil? }
            )
            Kernel.exit 0
          end

          run do |_, _, cmd|
            puts cmd.help
            Kernel.exit 0
          end
        end

        ret.add_command(CLI.generate)
        ret.add_command(CLI.json)
        ret.add_command(CLI.task)
        ret.add_command(CLI.tasks)
        ret.add_command(CLI.apply)
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
