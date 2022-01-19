# frozen_string_literal: true

require_relative "operation/attributes"

module Fluxo
  # I know that the underline instance method name is not the best, but I don't want to
  # conflict with the Operation step methods that are going to inherit this class.
  class Operation
    include Attributes

    class << self
      def flow(*methods)
        define_method(:call!) { |**attrs| __execute_flow__(steps: methods, attributes: attrs) }
      end

      def call(**attrs)
        instance = new

        begin
          instance.__execute_flow__(steps: [:call!], attributes: attrs)
        rescue ArgumentError, Fluxo::Error => e
          raise e
        rescue => e
          result = Fluxo::Result.new(type: :exception, value: e, operation: instance, ids: %i[error])
          Fluxo.config.error_handlers.each { |handler| handler.call(result) }
          strict? ? raise(e) : result
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
    def __execute_flow__(steps: [], attributes: {}, validate: true)
      transient_attributes, transient_ids = attributes.dup, Hash.new { |h, k| h[k] = [] }

      result = nil
      steps.unshift(:__validate__) if self.class.validations_proxy && validate # add validate step before the first step
      steps.each_with_index do |step, idx|
        if step.is_a?(Hash)
          step.each do |group_method, group_steps|
            send(group_method, **transient_attributes) do |group_attrs|
              result = __execute_flow__(validate: false, steps: group_steps, attributes: (group_attrs || transient_attributes))
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

    # Merge the result attributes with the new attributes. Also checks if the upcomming step
    # has the required attributes and transient attributes to a valid execution.
    # @param new_attributes [Hash] The new attributes
    # @param old_attributes [Hash] The old attributes
    # @param next_step [Symbol, Hash] The next step method
    def __merge_result_attributes__(new_attributes:, old_attributes:, next_step:)
      return old_attributes unless new_attributes.is_a?(Hash)

      old_attributes.merge(new_attributes.select { |k, _| k.is_a?(Symbol) })
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
