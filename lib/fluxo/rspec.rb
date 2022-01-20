require "rspec/expectations"

module Fluxo
  module Rspec
    def self.included(klass)
      klass.send(:include, OperationResultMatchers)
      klass.send(:include, InstanceMethods)
    end

    module OperationResultMatchers
      extend RSpec::Matchers::DSL

      matcher :result_succeed do
        match do |actual|
          return false unless actual.is_a?(Fluxo::Result)

          actual.success? && (@expected_value.nil? || values_match?(@expected_value, actual.value))
        end

        chain :with_value do |value|
          @expected_value = value
        end

        def differ
          RSpec::Support::Differ.new(
            object_preparer: ->(object) { RSpec::Matchers::Composable.surface_descriptions_in(object) },
            color: RSpec::Matchers.configuration.color?
          )
        end

        failure_message do |actual|
          return "expected that operation succeed, but got invalid result #{actual.inspect}" unless actual.is_a?(Fluxo::Result)

          msg = "expected that operation succeed, "
          msg += if actual.error?
            format("but the operation errored.\nException:\n %<e>p\n%<t>s", e: actual.value, t: actual.value.backtrace[0..5].join("\n"))
          elsif actual.failure?
            "but the operation failed."
          else
            "but got success with incorrect value"
          end
          if defined?(ActiveModel) && actual.value.is_a?(ActiveModel::Errors) && actual.value.any?
            msg += "\nActive Model errors:\n"
            actual.value.full_messages.each { |m| msg += "--> #{m}" }
          end
          msg += "\nDiff:" + differ.diff_as_string(actual.value, @expected_value) if @expected_value
          msg
        end

        failure_message_when_negated do |actual|
          return "expected that operation not to succeed, but got invalid result #{actual.inspect}" unless actual.is_a?(Fluxo::Result)

          "expected that operation not to succeed, but the operation succeeded."
        end
      end

      matcher :result_fail do # fail is a reserved word
        match do |actual|
          return false unless actual.is_a?(Fluxo::Result)

          actual.failure? && (@expected_value.nil? || values_match?(@expected_value, actual.value))
        end

        chain :with_value do |value|
          @expected_value = value
        end

        def differ
          RSpec::Support::Differ.new(
            object_preparer: ->(object) { RSpec::Matchers::Composable.surface_descriptions_in(object) },
            color: RSpec::Matchers.configuration.color?
          )
        end

        failure_message do |actual|
          return "expected that operation fail, but got invalid result #{actual.inspect}" unless actual.is_a?(Fluxo::Result)

          msg = "expected that operation fail, "
          if actual.success?
            msg += "but the operation succeeded."
            msg += "\nDiff:" + differ.diff_as_string(actual.value, @expected_value) if @expected_value
          elsif actual.error?
            msg += format("but the operation errored.\nException:\n %<e>p\n%<t>s", e: actual.value, t: actual.value.backtrace[0..5].join("\n"))
          else
            msg += "but got failure with incorrect value"
            msg += "\nDiff:" + differ.diff_as_string(actual.value, @expected_value) if @expected_value
          end
          if defined?(ActiveModel) && actual.value.is_a?(ActiveModel::Errors) && actual.value.any?
            msg += "\nActive Model errors:\n"
            actual.value.full_messages.each { |m| msg += "--> #{m}" }
          end
          msg
        end

        failure_message_when_negated do |actual|
          return "expected that operation not to fail, but got invalid result #{actual.inspect}" unless actual.is_a?(Fluxo::Result)

          "expected that operation not to fail, but the operation failed."
        end
      end

      matcher :result_error do
        match do |actual|
          return false unless actual.is_a?(Fluxo::Result)

          actual.error? && (@expected_value.nil? || values_match?(@expected_value, actual.value))
        end

        chain :with_value do |value|
          @expected_value = value
        end

        failure_message do |actual|
          return "expected that operation error, but got invalid result #{actual.inspect}" unless actual.is_a?(Fluxo::Result)

          msg = "expected that operation error, "
          msg += if actual.success?
            "but the operation succeeded"
          elsif actual.failure?
            "but the operation failed"
          else
            "but got error with #{@expected_value&.inspect || "incorrect"} instead of #{actual.value.inspect}"
          end
          if defined?(ActiveModel) && actual.value.is_a?(ActiveModel::Errors) && actual.value.any?
            msg += "\nActive Model errors:\n"
            actual.value.full_messages.each { |m| msg += "--> #{m}" }
          end
          msg
        end

        failure_message_when_negated do |actual|
          return "expected that operation not to error, but got invalid result #{actual.inspect}" unless actual.is_a?(Fluxo::Result)

          "expected that operation not to error, but the operation errored."
        end
      end
    end

    module InstanceMethods
      def expect_operation_result(**attrs)
        expect(operation_result(**attrs))
      end

      def operation_result(**kwargs)
        define_singleton_method(:result) { instance_variable_get(:@__result__) }
        @__result__ ||= described_class.call(**kwargs)
      end

      def expect_step_result(step_name, **kwargs)
        expect(step_result(step_name, **kwargs))
      end

      def step_result(step_name, **kwargs)
        @__operation__ = described_class.new
        define_singleton_method(:result) { instance_variable_get(:@__result__) }

        begin
          @__result__ = @__operation__.__execute_flow__(steps: [step_name], attributes: kwargs, validate: false)
        rescue => e
          @__result__ = Fluxo::Result.new(type: :exception, value: e, operation: @__operation__, ids: %i[error])
          Fluxo::Errors.raise_operation_error!(result)
        end

        @__result__
      end
    end
  end
end

::RSpec.configure do |config|
  config.include Fluxo::Rspec, type: :operation
end
