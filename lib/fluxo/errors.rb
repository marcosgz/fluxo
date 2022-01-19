module Fluxo
  class Error < StandardError
  end

  class InvalidResultError < Error
  end

  class ValidationDefinitionError < Error
  end
end
