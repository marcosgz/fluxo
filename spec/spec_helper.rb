# frozen_string_literal: true

require "bundler/setup"
require "floop"
require "pry"
require "support/hooks/active_model"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include Hooks::ActiveModel
end
