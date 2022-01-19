require "spec_helper"

RSpec.describe Fluxo::Operation do
  it "returns a class" do
    expect(Fluxo::Operation).to be_a(Class)
  end

  it "returns a class that inherits from Fluxo::Operation" do
    klass = Class.new(Fluxo::Operation)
    expect(klass.superclass).to eq(Fluxo::Operation)
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
        Class.new(Fluxo::Operation) do
          def call!(foo:, bar:, **)
            Success(foo: foo.to_s, bar: bar.to_s)
          end
        end
      end

      it "returns a Success result" do
        result = operation.call(foo: :foo, bar: :bar)
        expect(result).to be_success
        expect(result.value).to eq(foo: "foo", bar: "bar")
      end

      it "raises an error when the keyword attributes are not passed" do
        expect { operation.call }.to raise_error(ArgumentError)
      end
    end

    context "when the operation have transient flow attributes" do
      let(:operation) do
        Class.new(Fluxo::Operation) do
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
        expect { operation.call }.to raise_error(ArgumentError)
      end

      specify do
        result = operation.call(foo: :foo, bar: :bar)
        expect(result).to be_success
        expect(result.value).to eq(foo: "foo", bar: "bar", baz: "baz")
        reset_config!
      end
    end
  end

end
