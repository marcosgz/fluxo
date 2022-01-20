require "spec_helper"

RSpec.describe "operation with required attributes" do
  context "with a single operation" do
    it "validate presence of :attributes" do
      operation = Class.new(Fluxo::Operation) do
        attributes :user
        def call!(**)
          Success(:ok)
        end
      end
      expect { operation.call() }.to raise_error(ArgumentError)
      expect { operation.call(account: nil) }.to raise_error(ArgumentError)

      operation.strict = false
      expect(result = operation.call()).to be_failure
      expect(result.value).to eq(error: "Missing required attributes: user")

      expect(result = operation.call(account: nil)).to be_failure
      expect(result.value).to eq(error: "Missing required attributes: user")
    end

    it "validate presence of :validate_attributes" do
      operation = Class.new(Fluxo::Operation) do
        validate_attributes :user
        def call!(**)
          Success(:ok)
        end
      end
      expect { operation.call() }.to raise_error(ArgumentError)
      expect { operation.call(account: nil) }.to raise_error(ArgumentError)

      operation.strict = false
      expect(result = operation.call()).to be_failure
      expect(result.value).to eq(error: "Missing required attributes: user")

      expect(result = operation.call(account: nil)).to be_failure
      expect(result.value).to eq(error: "Missing required attributes: user")
    end
  end

  context "with a operation flow" do
    it "validate presence of :attributes" do
      operation = Class.new(Fluxo::Operation) do
        attributes :user

        flow :a, :b

        def a(**)
          Success(:ok)
        end

        def b(**)
          Success(:ok)
        end
      end
      expect { operation.call() }.to raise_error(ArgumentError)
      expect { operation.call(account: nil) }.to raise_error(ArgumentError)

      operation.strict = false
      expect(result = operation.call()).to be_failure
      expect(result.value).to eq(error: "Missing required attributes: user")

      expect(result = operation.call(account: nil)).to be_failure
      expect(result.value).to eq(error: "Missing required attributes: user")
    end

    it "validate presence of :validate_attributes" do
      operation = Class.new(Fluxo::Operation) do
        validate_attributes :user

        flow :a, :b

        def a(**)
          Success(:ok)
        end

        def b(**)
          Success(:ok)
        end
      end
      expect { operation.call() }.to raise_error(ArgumentError)
      expect { operation.call(account: nil) }.to raise_error(ArgumentError)

      operation.strict = false
      expect(result = operation.call()).to be_failure
      expect(result.value).to eq(error: "Missing required attributes: user")

      expect(result = operation.call(account: nil)).to be_failure
      expect(result.value).to eq(error: "Missing required attributes: user")
    end
  end
end
