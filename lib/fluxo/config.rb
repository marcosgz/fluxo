# frozen_string_literal: true

module Fluxo
  class << self
    def config
      @config ||= Config.new
      yield(@config) if block_given?
      @config
    end
    alias_method :configure, :config
  end

  class Config
    attr_reader :error_handlers

    # When set to true, the result of a falsey operation will be wrapped in a Failure.
    attr_accessor :wrap_falsey_result

    # When set to true, the result of a truthy operation will be wrapped in a Success.
    attr_accessor :wrap_truthy_result

    # Auto handle errors/exceptions.
    attr_writer :strict

    def initialize
      @error_handlers = []
      @wrap_falsey_result = false
      @wrap_truthy_result = false
      @strict = false
    end

    def strict?
      !!@strict
    end
  end
end
