# frozen_string_literal: true

require_relative "fluxo/version"
require_relative "fluxo/config"
require_relative "fluxo/errors"
require_relative "fluxo/operation"
require_relative "fluxo/result"

begin
  require "active_model"
  require_relative "fluxo/active_model_extension"
rescue LoadError
  # do nothing
end

module Fluxo
end
