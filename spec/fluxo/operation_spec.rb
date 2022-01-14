require "spec_helper"

RSpec.describe Fluxo::Operation do
  it "returns a class" do
    expect(Fluxo::Operation).to be_a(Class)
  end

  it "returns a class that inherits from Fluxo::Operation" do
    klass = Class.new(Fluxo::Operation)
    expect(klass.superclass).to eq(Fluxo::Operation)
    expect(klass.attribute_names).to eq([])
  end

  describe ".Opearation" do
    it "define attributes an return operation superclass" do
      klass = Fluxo::Operation(:foo, :bar)
      expect(klass.superclass).to eq(Fluxo::Operation)
      expect(klass.attribute_names).to eq([:foo, :bar])
      expect(klass.instance_methods).not_to include(:foo, :bar)
    end

    it "inherits from Fluxo::Operation using input attributes and block" do
      klass = Class.new(Fluxo::Operation(:foo, :bar))
      expect(klass.superclass.superclass).to eq(Fluxo::Operation)
      expect(klass.attribute_names).to eq([:foo, :bar])
      expect(klass.instance_methods).not_to include(:foo, :bar)
    end
  end

  describe ".attributes" do
    it "sets the attributes" do
      klass = Class.new(Fluxo::Operation)
      klass.attributes(:foo, :bar)
      expect(klass.attribute_names).to eq([:foo, :bar])
      expect(klass).to be_attribute(:foo)
      expect(klass).to be_attribute(:bar)
      expect(klass).not_to be_attribute(:baz)
    end

    it "ignores duplicated attributes" do
      klass = Class.new(Fluxo::Operation)
      klass.attributes(:foo, :bar)
      expect(klass.attribute_names).to eq([:foo, :bar])
      klass.attributes(:foo, :bar)
      expect(klass.attribute_names).to eq([:foo, :bar])
    end
  end

  describe ".call" do
    context "when the call! method is not defined" do
      let(:operation) do
        Class.new(Fluxo::Operation)
      end

      it "raises an error" do
        expect { operation.call }.to raise_error(NotImplementedError)
      end
    end

    context "when the call! method is defined with a Success result" do
      let(:operation) do
        Class.new(Fluxo::Operation) do
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
        Class.new(Fluxo::Operation) do
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
        Class.new(Fluxo::Operation) do
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
        Class.new(Fluxo::Operation(:foo, :bar)) do
          def call!(foo:, bar:, **)
            Success(foo: "foo", bar: "bar")
          end
        end
      end

      it "returns a Success result" do
        result = operation.call(foo: :foo, bar: :bar)
        expect(result).to be_success
        expect(result.value).to eq(foo: "foo", bar: "bar")
      end

      it "raises an error when the keyword attributes are not passed" do
        expect { operation.call }.to raise_error(Fluxo::MissingAttributeError)
      end

      it "ignores extra attributes when global sloppy_attributes is enabled" do
        Fluxo.config.sloppy_attributes = true
        result = operation.call(foo: :foo, bar: :bar, baz: :baz)
        expect(result).to be_success
        expect(result.value).to eq(foo: "foo", bar: "bar")
        reset_config!
      end

      it "ignores extra attributes when operation sloppy_attributes is enabled" do
        operation.sloppy_attributes = true
        expect(operation).to be_sloppy_attributes
        result = operation.call(foo: :foo, bar: :bar, baz: :baz)
        expect(result).to be_success
        expect(result.value).to eq(foo: "foo", bar: "bar")
        operation.sloppy_attributes = false
      end
    end

    context "when the operation have transient flow attributes" do
      let(:operation) do
        Class.new(Fluxo::Operation(:foo)) do
          attributes :bar
          transient_attributes :baz

          flow :foo, :bar, :baz, :wrap

          def foo(foo:, **)
            Success(foo: foo.to_s)
          end

          def bar(bar:, **)
            Success(bar: bar.to_s, baz: :baz)
          end

          def baz(baz:, **)
            Success(baz: baz.to_s)
          end

          def wrap(**attrs)
            Success(attrs)
          end
        end
      end

      it "raises an error when the keyword from attributes are not passed" do
        expect { operation.call }.to raise_error(Fluxo::MissingAttributeError)
      end

      it "ignores extra attributes that are merged during the flow execution when global sloppy_attributes is enabled" do
        Fluxo.config.sloppy_transient_attributes = true
        result = operation.call(foo: :foo, bar: :bar)
        expect(result).to be_success
        expect(result.value).to eq(foo: "foo", bar: "bar", baz: "baz")
        reset_config!
      end

      it "ignores extra attributes that are merged during the flow execution when operation sloppy_transient_attributes is enabled" do
        operation.sloppy_transient_attributes = true
        expect(operation).to be_sloppy_transient_attributes
        result = operation.call(foo: :foo, bar: :bar)
        expect(result).to be_success
        expect(result.value).to eq(foo: "foo", bar: "bar", baz: "baz")
        operation.sloppy_transient_attributes = false
      end
    end
  end

end
