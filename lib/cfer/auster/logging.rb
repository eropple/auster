# frozen_string_literal: true

require "logger"

module Cfer
  module Auster
    module Logging
      def self.logger
        @logger
      end

      def self.logdev
        @logdev
      end

      # rubocop:disable Style/AccessorMethodName
      def self.set_logdev(logdev)
        @logdev = logdev
        @logger = Logger.new(@logdev)
      end

      set_logdev($stderr)
      @logger.level = Logger::INFO

      module Mixin
        def logger
          Cfer::Auster::Logging.logger
        end
      end
    end
  end
end
