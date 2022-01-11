# frozen_string_literal: true

require "spec_helper"

RSpec.describe Floop::Config do
  describe ".config" do
    it { expect(Floop).to respond_to(:config) }
    it { expect(Floop).not_to respond_to(:"config=") }
    it { expect(Floop.config).to be_an_instance_of(Floop::Config) }
    it { expect { Floop.config(&:to_s) }.not_to raise_error }
  end
end
