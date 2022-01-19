# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fluxo::Config do
  before do
    reset_config!
  end

  describe "#wrap_truthy_result" do
    it "should be false by default" do
      expect(Fluxo.config.wrap_truthy_result).to be_falsey
    end

    it "should be true when set to true" do
      Fluxo.config.wrap_truthy_result = true
      expect(Fluxo.config.wrap_truthy_result).to be_truthy
    end
  end

  describe "#wrap_falsey_result" do
    it "should be false by default" do
      expect(Fluxo.config.wrap_falsey_result).to be_falsey
    end

    it "should be true when set to true" do
      Fluxo.config.wrap_falsey_result = true
      expect(Fluxo.config.wrap_falsey_result).to be_truthy
    end
  end

  describe "#strict?" do
    it "should be false by default" do
      expect(Fluxo.config.strict?).to be_falsey
    end

    it "should be true when set to true" do
      Fluxo.config.strict = true
      expect(Fluxo.config.strict?).to be_truthy
    end
  end
end
