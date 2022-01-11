module Floop
  class Error < StandardError
  end

  class InvalidResultError < Error
  end

  class InvalidValidationsError < Error
  end
end
