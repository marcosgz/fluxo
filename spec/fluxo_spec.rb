# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fluxo do
  it "has a version number" do
    expect(Fluxo::VERSION).not_to be nil
  end

  it "should only be executed when the activemodel gem is loaded", active_model: true do
    expect(true).to eq(true)
  end
end
