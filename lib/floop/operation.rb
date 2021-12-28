# frozen_string_literal: true

require_relative "operation/constructor"
require_relative "operation/attributes"

module Floop
  class Operation
    include Attributes
    include Constructor
    def_Operation(::Floop)

    def call!
      raise NotImplementedError, <<~ERROR
        You must implement the #call! method in your operation.
        For complexes operations, you can use the #flow method instead.
      ERROR
    end
  end
end
