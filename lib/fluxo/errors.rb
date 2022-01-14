module Fluxo
  class Error < StandardError
  end

  class InvalidResultError < Error
  end

  class AttributeError < Error
  end

  class NotDefinedAttributeError < AttributeError
  end

  class MissingAttributeError < AttributeError
  end

  class ValidationDefinitionError < Error
  end
end
