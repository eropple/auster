# frozen_string_literal: true
require "kwalify"

module Cfer
  module Auster
    class Config
      include Cfer::Auster::Logging::Mixin

      attr_reader :name
      attr_reader :aws_region
      attr_reader :data

      def initialize(name:, aws_region:, data:)
        raise "name must be a String" unless name.is_a?(String)
        raise "aws_region must be a String" unless aws_region.is_a?(String)
        raise "data must be a Hash" unless data.is_a?(Hash)

        @name = name.dup.freeze
        @aws_region = aws_region.dup.freeze
        @data = data.deep_symbolize_keys

        @data[:PlanID] = @name
        @data[:AWSRegion] = @aws_region

        IceNine.deep_freeze(@data)
      end

      def full_name
        "#{aws_region}/#{name}"
      end

      def env_vars_for_shell
        {
          "PLAN_ID" => name,
          "AWS_REGION" => aws_region,
          "AWS_DEFAULT_REGION" => aws_region
        }
      end

      class << self
        include Cfer::Auster::Logging::Mixin

        def from_file(name:, aws_region:, data_file:, schema_file:)
          logger.debug "Loading config set from #{data_file}"
          schema = schema_file.nil? ? nil : Kwalify::Yaml.load_file(schema_file)
          validator = schema.nil? ? nil : Kwalify::Validator.new(schema)

          parser = Kwalify::Yaml::Parser.new(validator)

          data = parser.parse_file(data_file)
          errors = parser.errors()

          if errors && !errors.empty?
            # TODO: make a better error to raise that can encapsulate these validation failures.
            msg = "Schema validation failed for #{data_file}."

            logger.error "Schema validation failed for #{data_file}."
            errors.each do |e|
              logger.error "#{e.linenum}:#{e.column} [#{e.path}] #{e.message}"
            end

            raise msg
          end

          Config.new(name: name, aws_region: aws_region, data: data)
        end
      end
    end
  end
end
