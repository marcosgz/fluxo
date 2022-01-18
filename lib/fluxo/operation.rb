# frozen_string_literal: true

require_relative "operation/constructor"
require_relative "operation/attributes"

module Fluxo
  # I know that the underline instance method name is not the best, but I don't want to
  # conflict with the Operation step methods that are going to inherit this class.
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
      transient_attributes, transient_ids = attributes.dup, Hash.new { |h, k| h[k] = [] }
      __validate_attributes__(first_step: steps.first, attributes: transient_attributes)

      result = nil
      steps.unshift(:__validate__) if self.class.validations_proxy # add validate step before the first step
      steps.each_with_index do |step, idx|
        if step.is_a?(Hash)
          step.each do |group_method, group_steps|
            send(group_method, **transient_attributes) do |group_attrs|
              result = __execute_flow__(steps: group_steps, attributes: (group_attrs || transient_attributes))
            end
            break unless result.success?
          end
        else
          result = __wrap_result__(send(step, **transient_attributes))
          transient_ids[result.type].push(*result.ids)
        end

        break unless result.success?

        if steps[idx + 1]
          transient_attributes = __merge_result_attributes__(
            new_attributes: result.value,
            old_attributes: transient_attributes,
            next_step: steps[idx + 1]
          )
        end
      end
      result.mutate(ids: transient_ids[result.type].uniq, operation: self)
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

    # Validates the operation was called with all the required keyword arguments.
    # @param first_step [Symbol, Hash] The first step method
    # @param attributes [Hash] The attributes to validate
    # @return [void]
    # @raise [MissingAttributeError] When a required attribute is missing
    def __validate_attributes__(attributes:, first_step:)
      if self.class.strict_attributes? && (extra = attributes.keys - self.class.attribute_names).any?
        raise NotDefinedAttributeError, <<~ERROR
          The following attributes are not defined: #{extra.join(", ")}

          You can use the #{self.class.name}.attributes method to specify list of allowed attributes.
          Or you can disable strict attributes mode by setting the strict_attributes to true.

          Source:
          #{__method_source__(first_step)}
        ERROR
      end

      step_method = __expand_step_method__(first_step)
      method(step_method).parameters.select { |type, _| type == :keyreq }.each do |(_type, name)|
        raise(MissingAttributeError, "Missing :#{name} attribute on #{self.class.name}#{step_method} step method.") unless attributes.key?(name)
      end
    end

    # Merge the result attributes with the new attributes. Also checks if the upcomming step
    # has the required attributes and transient attributes to a valid execution.
    # @param new_attributes [Hash] The new attributes
    # @param old_attributes [Hash] The old attributes
    # @param next_step [Symbol, Hash] The next step method
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

          Source:
          #{__method_source__(next_step)}
        ERROR
      end

      step_method = __expand_step_method__(next_step)
      method(step_method).parameters.select { |type, _| type == :keyreq }.each do |(_type, name)|
        raise(MissingAttributeError, "Missing :#{name} transient attribute on #{self.class.name}##{step_method} step method.") unless attributes.key?(name)
      end

      attributes
    end

    def __method_source__(step)
      method_name = __expand_step_method__(step)
      format("* %<method_name>s: %<source>s",
        method_name: method_name,
        source: method(method_name).source_location.join(":"),
      )
    end

    # Return the step method as an array. When it's a hash it suppose to be a
    # be a step group. In this case return its first key and its first value as
    # the array of step methods.
    #
    # @param step [Symbol, Hash] The step method name
    def __expand_step_method__(step)
      return step unless step.is_a?(Hash)

      step.keys.first
    end

    # Execute active_model validation as a flow step.
    # @param attributes [Hash] The attributes to validate
    # @return [Fluxo::Result] The result of the validation
    def __validate__(**attributes)
      self.class.validations_proxy.validate!(self, **attributes)
    end

    # Wrap the step method result in a Fluxo::Result object.
    #
    # @param result [Fluxo::Result, *Object] The object to wrap
    # @raise [Fluxo::InvalidResultError] When the result is not a Fluxo::Result config
    #  is set to not wrap results.
    # @return [Fluxo::Result] The wrapped result
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
