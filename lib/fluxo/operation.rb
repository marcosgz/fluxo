# frozen_string_literal: true

require_relative "operation/constructor"
require_relative "operation/attributes"

module Fluxo
  class Operation
    include Attributes
    include Constructor

    def_Operation(::Fluxo)

    class << self
      def flow(*methods)
        define_method(:call!) { |**attrs| __execute_flow__(steps: methods, attributes: attrs) }
      end

      def call(**attrs)
        instance = new

        begin
          instance.__execute_flow__(steps: [:call!], attributes: attrs)
        rescue InvalidResultError, AttributeError, ValidationDefinitionError => e
          raise e
        rescue => e
          Fluxo::Result.new(type: :exception, value: e, operation: instance, ids: %i[error]).tap do |result|
            Fluxo.config.error_handlers.each { |handler| handler.call(result) }
          end
        end
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
    def __execute_flow__(steps: [], attributes: {})
      transient_attributes = attributes.dup
      __validate_attributes__(first_step: steps.first, attributes: transient_attributes)

      result = nil
      steps.unshift(:__validate__) if self.class.validations_proxy # add validate step before the first step
      steps.each_with_index do |step, idx|
        result = __wrap_result__(send(step, **transient_attributes))
        break unless result.success?

        if steps[idx + 1]
          transient_attributes = __merge_result_attributes__(
            new_attributes: result.value,
            old_attributes: transient_attributes,
            next_step: steps[idx + 1]
          )
        end
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
      Fluxo::Result.new(**attrs)
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
      Fluxo::Result.new(**attrs)
    end

    def Void
      Success(:void) { nil }
    end

    private

    def __validate_attributes__(attributes:, first_step:)
      if self.class.strict_attributes? && (extra = attributes.keys - self.class.attribute_names).any?
        raise NotDefinedAttributeError, <<~ERROR
          The following attributes are not defined: #{extra.join(", ")}

          You can use the #{self.class.name}.attributes method to specify list of allowed attributes.
          Or you can disable strict attributes mode by setting the strict_attributes to true.
        ERROR
      end

      method(first_step).parameters.select { |type, _| type == :keyreq }.each do |(_type, name)|
        raise(MissingAttributeError, "Missing :#{name} attribute on #{self.class.name}#{first_step} step method.") unless attributes.key?(name)
      end
    end

    def __merge_result_attributes__(new_attributes:, old_attributes:, next_step:)
      return old_attributes unless new_attributes.is_a?(Hash)

      attributes = old_attributes.merge(new_attributes)
      allowed_attrs = self.class.attribute_names + self.class.transient_attribute_names
      if self.class.strict_transient_attributes? &&
          (extra = attributes.keys - allowed_attrs).any?
        raise NotDefinedAttributeError, <<~ERROR
          The following transient attributes are not defined: #{extra.join(", ")}

          You can use the #{self.class.name}.transient_attributes method to specify list of allowed attributes.
          Or you can disable strict transient attributes mode by setting the strict_transient_attributes to true.
        ERROR
      end

      method(next_step).parameters.select { |type, _| type == :keyreq }.each do |(_type, name)|
        raise(MissingAttributeError, "Missing :#{name} transient attribute on #{self.class.name}##{next_step} step method.") unless attributes.key?(name)
      end

      attributes
    end

    def __validate__(**attributes)
      self.class.validations_proxy.validate!(self, **attributes)
    end

    def __wrap_result__(result)
      if result.is_a?(Fluxo::Result)
        return result
      elsif Fluxo.config.wrap_falsey_result && !result
        return Failure(:falsey) { result }
      elsif Fluxo.config.wrap_truthy_result && result
        return Success(:truthy) { result }
      end

      raise InvalidResultError, <<~ERROR
        The result of each step must be a Fluxo::Result.
        You can use the #Success() and #Failure() methods to create a result.

        This behavior can be changed by setting the Fluxo.config.wrap_falsey_result and Fluxo.config.wrap_truthy_result
        configuration options.

        The result of the operation is: #{result.inspect}
      ERROR
    end
  end
end
