# frozen_string_literal: true

module Floop
  def self.config
    @config ||= Config.new
    yield(@config) if block_given?
    @config
  end

  class Config
    attr_reader :error_handlers

    def initialize
      @error_handlers = []
    end
  end
end
