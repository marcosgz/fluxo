module Fluxo
  module Errors
    # @param result [Fluxo::Result] The result to be checked
    def self.raise_operation_error!(result)
      raise result if result.is_a?(Exception)
      raise result.value if result.operation.class.strict?

      [SyntaxError, ArgumentError, NoMethodError, Fluxo::Error].each do |exception|
        raise result.value if result.value.is_a?(exception)
      end
    end
  end

  class Error < StandardError
  end

  class InvalidResultError < Error
  end

  class ValidationDefinitionError < Error
  end
end
