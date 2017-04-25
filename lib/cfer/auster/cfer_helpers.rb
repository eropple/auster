module Cfer
  module Auster
    module CferHelpers
      CFIZER_DEFAULT_CAPTURE_REGEXP = /C\{(?<directive>.*?)\}/

      def eval_file(filename)
        instance_eval IO.read(filename), filename
      end

      def import(name)
        { "Fn::ImportValue" => _exported_name(name) }
      end

      def export(name, value)
        output name, value, Export: { Name: _exported_name(name) }
      end

      def _exported_name(name)
        "#{parameters[:PlanID]}--#{name}"
      end

      def cfize(text, capture_regexp: nil)
        CferHelpers.cfize(text, capture_regexp: capture_regexp)
      end

      def self.cfize(text, capture_regexp: nil)
        raise "'text' must be a string." unless text.is_a?(String)

        capture_regexp ||= CFIZER_DEFAULT_CAPTURE_REGEXP

        raise "'capture_regexp' must be a Regexp." unless capture_regexp.is_a?(Regexp)
        raise "'capture_regexp' must include a 'contents' named 'directive'." \
          unless capture_regexp.named_captures.key?("directive")

        working = []
        until working[-2] == "" && working[-1] == "" do
          if working.empty?
            working = text.partition(capture_regexp)
          else
            working[-1] = working[-1].partition(capture_regexp)
            working = working.flatten
          end
        end

        cfizer = Cfizer.new
        Cfizer::Fn.join("", working.map do |token|
          match = capture_regexp.match(token)
          if match.nil?
            token
          else
            cfizer.cfize(match["directive"])
          end
        end.reject { |t| t == ""})
      end

      class Cfizer
        begin
          include Cfer::Core::Functions
        rescue NameError => _
          # we need to fall back to the old Cfer setup
          include Cfer::Core
          include Cfer::Cfn
        end

        def cfize(directive)
          instance_eval directive
        end
      end
    end
  end
end
