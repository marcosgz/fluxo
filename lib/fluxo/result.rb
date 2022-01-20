# frozen_string_literal: true

module Fluxo
  class Result
    ATTRIBUTES = %i[operation type value transient_attributes ids].freeze
    attr_reader(*ATTRIBUTES)

    # @param options [Hash]
    # @option options [Fluxo::Operation] :operation The operation instance that gererated this result
    # @option options [symbol] :type The type of the result. Allowed types: :ok, :failure, :exception
    # @option options [Any] :value The value of the result.
    # @option options [Array<symbol>] :ids An identification to be used with the on_<success|failure|error> handlers
    def initialize(operation:, type:, value:, ids: nil)
      @operation = operation
      @value = value
      @type = type
      @ids = Array(ids)
    end

    def mutate(**attrs)
      attrs.each do |key, value|
        instance_variable_set("@#{key}", value) if ATTRIBUTES.include?(key)
      end
      self
    end

    def ==(other)
      other.is_a?(self.class) && other.operation == operation && other.type == type && other.value == value && other.ids == ids
    end
    alias_method :eql?, :==

    # @return [Boolean] true if the result is a success
    def success?
      type == :ok
    end

    # @return [Boolean] true if the result is a failure
    def failure?
      type == :failure
    end

    # @return [Boolean] true if the result is an exception
    def error?
      type == :exception
    end

    def on_success(*handler_ids)
      tap { yield(self) if success? && (handler_ids.none? || (ids & handler_ids).any?) }
    end

    def on_failure(*handler_ids)
      tap { yield(self) if failure? && (handler_ids.none? || (ids & handler_ids).any?) }
    end

    def on_error(*handler_ids)
      tap { yield(self) if error? && (handler_ids.none? || (ids & handler_ids).any?) }
    end
  end
end
