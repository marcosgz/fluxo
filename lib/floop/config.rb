# frozen_string_literal: true

module Floop
  def self.config
    @config ||= Config.new
    yield(@config) if block_given?
    @config
  end

  class Config
    attr_reader :error_handlers

    # When set to true, the result of a falsey operation will be wrapped in a Failure.
    attr_accessor :wrap_falsey_result

    # When set to true, the result of a truthy operation will be wrapped in a Success.
    attr_accessor :wrap_truthy_result

    # When set to true, the operation will not validate the transient_attributes defition during the flow step execution.
    attr_accessor :sloppy_transient_attributes

    # When set to true, the operation will not validate attributes definition before calling the operation.
    attr_accessor :sloppy_attributes

    def initialize
      @error_handlers = []
      @wrap_falsey_result = false
      @wrap_truthy_result = false
      @sloppy_transient_attributes = false
      @sloppy_attributes = false
    end
  end
end
