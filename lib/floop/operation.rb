# frozen_string_literal: true

require_relative "operation/constructor"
require_relative "operation/attributes"

module Floop
  class Operation
    include Attributes
    include Constructor

    def_Operation(::Floop)

    class << self
      def flow(*methods)
        define_method(:call!) { |**| __execute_flow__(steps: methods) }
      end

      def call(**attrs)
        instance = new(**attrs) # @idea pass attributes as argument to the first step to make it imutable

        begin
          instance.__execute_flow__(steps: [:call!])
        rescue InvalidResultError, InvalidValidationsError => e
          raise e
        rescue => e
          Floop::Result.new(type: :exception, value: e, operation: instance, ids: %i[error]).tap do |result|
            Floop.config.error_handlers.each { |handler| handler.call(result) }
          end
        end
      end
    end

    def initialize(**attrs)
      attrs.each do |key, value|
        raise(ArgumentError, "Undefined #{key.inspect} attribute") unless self.class.attribute?(key)

        instance_variable_set(:"@#{key}", value)
      end
    end

    def call!(**)
      raise NotImplementedError, <<~ERROR
        You must implement the #call! method in your operation.
        For complexes operations, you can use the #flow method instead.
      ERROR
    end

    # Calls step-method by step-method always passing the value to the next step
    # If one of the methods is a failure stop the execution and return a result.
    def __execute_flow__(steps: [])
      result = nil
      steps.unshift(:__validate__) if self.class.validations_proxy
      steps.each do |step|
        result = __wrap_result__(send(step))
        break unless result.success?
      end
      result
    end

    # @param value_or_result_id [Any] The value for the result or the id when the result comes from block
    def Success(value_or_result_id = nil)
      attrs = {type: :ok, operation: self}
      if block_given?
        attrs[:ids] = value_or_result_id
        attrs[:value] = yield
      else
        attrs[:value] = value_or_result_id
      end
      Floop::Result.new(**attrs)
    end

    # @param value_or_result_id [Any] The value for the result or the id when the result comes from block
    def Failure(value_or_result_id = nil)
      attrs = {type: :failure, operation: self}
      if block_given?
        attrs[:ids] = value_or_result_id
        attrs[:value] = yield
      else
        attrs[:value] = value_or_result_id
      end
      Floop::Result.new(**attrs)
    end

    def Void
      Success(:void) { nil }
    end

    private

    def __validate__(**)
      self.class.validations_proxy.validate!(self)
    end

    def __wrap_result__(result)
      if result.is_a?(Floop::Result)
        return result
      elsif Floop.config.wrap_falsey_result && !result
        return Failure(:falsey) { result }
      elsif Floop.config.wrap_truthy_result && result
        return Success(:truthy) { result }
      end

      raise InvalidResultError, <<~ERROR
        The result of each step must be a Floop::Result.
        You can use the #Success() and #Failure() methods to create a result.

        This behavior can be changed by setting the Floop.config.wrap_falsey_result and Floop.config.wrap_truthy_result
        configuration options.

        The result of the operation is: #{result.inspect}
      ERROR
    end
  end
end
