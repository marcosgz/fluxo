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
    it "define attributes an return operation superclass" do
      klass = Floop::Operation(:foo, :bar)
      expect(klass.superclass).to eq(Floop::Operation)
      expect(klass.attribute_names).to eq([:foo, :bar])
      expect(klass.instance_methods).to include(:foo, :bar)
    end

    it "inherits from Floop::Operation using input attributes and block" do
      klass = Class.new(Floop::Operation(:foo, :bar))
      expect(klass.superclass.superclass).to eq(Floop::Operation)
      expect(klass.attribute_names).to eq([:foo, :bar])
      expect(klass.instance_methods).to include(:foo, :bar)
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

  describe ".call" do
    context "when the call! method is not defined" do
      let(:operation) do
        Class.new(Floop::Operation)
      end

      it "raises an error" do
        expect { operation.call }.to raise_error(NotImplementedError)
      end
    end

    context "when the call! method is defined with a Success result" do
      let(:operation) do
        Class.new(Floop::Operation) do
          def call!
            Success(:foo)
          end
        end
      end

      it "returns a Success result" do
        expect(operation.call).to be_success
      end
    end

    context "when the call! method is defined with a Failure result" do
      let(:operation) do
        Class.new(Floop::Operation) do
          def call!
            Failure(:foo)
          end
        end
      end

      it "returns a Failure result" do
        expect(operation.call).to be_failure
      end
    end

    context "when the call! method is defined with a Void result" do
      let(:operation) do
        Class.new(Floop::Operation) do
          def call!
            Void()
          end
        end
      end

      it "returns a Void result" do
        expect(operation.call).to be_success
      end
    end

    context "when the operation have attributes" do
      let(:operation) do
        Class.new(Floop::Operation(:foo, :bar)) do
          def call!
            Success(foo => bar)
          end
        end
      end

      it "returns a Success result" do
        result = operation.call(foo: :foo, bar: :bar)
        expect(result).to be_success
        expect(result.value).to eq(foo: :bar)
      end
    end
  end
end
