# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fluxo do
  it "has a version number" do
    expect(Fluxo::VERSION).not_to be nil
  end

  it "should only be executed when the activemodel gem is loaded", active_model: true do
    expect(true).to eq(true)
  end

  describe ".config" do
    it { expect(Fluxo).to respond_to(:config) }
    it { expect(Fluxo).not_to respond_to(:"config=") }
    it { expect(Fluxo.config).to be_an_instance_of(Fluxo::Config) }
    it { expect { Fluxo.config(&:to_s) }.not_to raise_error }
  end

  describe ".configure" do
    it { expect(Fluxo).to respond_to(:configure) }
    it { expect(Fluxo).not_to respond_to(:"configure=") }
    it { expect { Fluxo.configure(&:to_s) }.not_to raise_error }
  end
end
