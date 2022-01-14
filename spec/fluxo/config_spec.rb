# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fluxo::Config do
  before do
    reset_config!
  end

  describe ".config" do
    it { expect(Fluxo).to respond_to(:config) }
    it { expect(Fluxo).not_to respond_to(:"config=") }
    it { expect(Fluxo.config).to be_an_instance_of(Fluxo::Config) }
    it { expect { Fluxo.config(&:to_s) }.not_to raise_error }
  end

  describe ".wrap_truthy_result" do
    it "should be false by default" do
      expect(Fluxo.config.wrap_truthy_result).to be_falsey
    end

    it "should be true when set to true" do
      Fluxo.config.wrap_truthy_result = true
      expect(Fluxo.config.wrap_truthy_result).to be_truthy
    end
  end

  describe ".wrap_falsey_result" do
    it "should be false by default" do
      expect(Fluxo.config.wrap_falsey_result).to be_falsey
    end

    it "should be true when set to true" do
      Fluxo.config.wrap_falsey_result = true
      expect(Fluxo.config.wrap_falsey_result).to be_truthy
    end
  end
end
