# frozen_string_literal: true

require "spec_helper"

RSpec.describe Floop::Config do
  before do
    reset_config!
  end

  describe ".config" do
    it { expect(Floop).to respond_to(:config) }
    it { expect(Floop).not_to respond_to(:"config=") }
    it { expect(Floop.config).to be_an_instance_of(Floop::Config) }
    it { expect { Floop.config(&:to_s) }.not_to raise_error }
  end

  describe ".wrap_truthy_result" do
    it "should be false by default" do
      expect(Floop.config.wrap_truthy_result).to be_falsey
    end

    it "should be true when set to true" do
      Floop.config.wrap_truthy_result = true
      expect(Floop.config.wrap_truthy_result).to be_truthy
    end
  end

  describe ".wrap_falsey_result" do
    it "should be false by default" do
      expect(Floop.config.wrap_falsey_result).to be_falsey
    end

    it "should be true when set to true" do
      Floop.config.wrap_falsey_result = true
      expect(Floop.config.wrap_falsey_result).to be_truthy
    end
  end
end
