require "spec_helper"

RSpec.describe Floop::Operation do
  it "returns a class" do
    expect(Floop::Operation).to be_a(Class)
  end

  it "returns a class that inherits from Floop::Operation" do
    klass = Class.new(Floop::Operation)
    expect(klass.superclass).to eq(Floop::Operation)
    expect(klass.attribute_names).to eq([])
  end

  describe ".Opearation" do
    it "inherits from Floop::Operation using input attributes" do
      klass = Floop::Operation(:foo, :bar)
      expect(klass.superclass).to eq(Floop::Operation)
      expect(klass.attribute_names).to eq([:foo, :bar])
    end
  end

  describe ".attributes" do
    it "sets the attributes" do
      klass = Class.new(Floop::Operation)
      klass.attributes(:foo, :bar)
      expect(klass.attribute_names).to eq([:foo, :bar])
      expect(klass).to be_attribute(:foo)
      expect(klass).to be_attribute(:bar)
      expect(klass).not_to be_attribute(:baz)
    end

    it "ignores duplicated attributes" do
      klass = Class.new(Floop::Operation)
      klass.attributes(:foo, :bar)
      expect(klass.attribute_names).to eq([:foo, :bar])
      klass.attributes(:foo, :bar)
      expect(klass.attribute_names).to eq([:foo, :bar])
    end
  end
end
