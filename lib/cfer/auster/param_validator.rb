# frozen_string_literal: true

module Cfer
  module Auster
    class ParamValidator
      def initialize(&validator)
        raise "validator must be a Proc." unless validator.is_a?(Proc)
        raise "validator must be arity 2." unless validator.arity == 2

        @validator = validator
      end

      def validate(parameters)
        raise "parameters must be a Hash." unless parameters.is_a?(Hash)

        errors = []
        @validator.call(parameters, errors)
        errors
      end
    end
  end
end
