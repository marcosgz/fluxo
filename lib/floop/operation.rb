# frozen_string_literal: true

require_relative "operation/constructor"
require_relative "operation/attributes"

module Floop
  class Operation
    include Attributes
    include Constructor

    def_Operation(::Floop)

    class << self
      def call(**attrs)
        instance = new(**attrs) # @idea pass attributes as argument to the first step to make it imutable

        begin
          instance.call!
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

    def call!
      raise NotImplementedError, <<~ERROR
        You must implement the #call! method in your operation.
        For complexes operations, you can use the #flow method instead.
      ERROR
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
  end
end
