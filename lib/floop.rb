# frozen_string_literal: true

require_relative "floop/version"
require_relative "floop/config"
require_relative "floop/operation"
require_relative "floop/result"

begin
  require "active_model"
  require_relative "floop/active_model_extension"
rescue LoadError
  # do nothing
end

module Floop
end
