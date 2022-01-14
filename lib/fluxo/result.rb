# frozen_string_literal: true

module Fluxo
  class Result
    attr_reader :operation, :type, :value, :ids

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

    def on_success(handler_id = nil)
      tap { yield(self) if success? && (handler_id.nil? || ids.include?(handler_id)) }
    end

    def on_failure(handler_id = nil)
      tap { yield(self) if failure? && (handler_id.nil? || ids.include?(handler_id)) }
    end

    def on_error(handler_id = nil)
      tap { yield(self) if error? && (handler_id.nil? || ids.include?(handler_id)) }
    end
  end
end
