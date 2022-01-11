# frozen_string_literal: true

module Floop
  def self.config
    @config ||= Config.new
    yield(@config) if block_given?
    @config
  end

  class Config
    attr_reader :error_handlers
    attr_accessor :wrap_falsey_result, :wrap_truthy_result

    def initialize
      @error_handlers = []
      @wrap_falsey_result = false
      @wrap_truthy_result = false
    end
  end
end
