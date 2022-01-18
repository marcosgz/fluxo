require "spec_helper"

RSpec.describe "operation execution with a flow with external operation result" do
  describe ".on_success" do
    let(:double_operation_klass) do
      Class.new(Fluxo::Operation(:num)) do
        def call!(num:)
          Success(:result) { {num: num * 2} }
        end
      end
    end

    let(:main_operation_klass) do
      Class.new(Fluxo::Operation(:num, :external)) do
        flow :plus_one, :double

        private

        def plus_one(num:, **)
          Success(num: num + 1)
        end

        def double(num:, external:, **)
          external.call(num: num)
        end
      end
    end

    it "coerces the value of sub operation to the main operation" do
      result = main_operation_klass.call(num: 2, external: double_operation_klass)
      expect(result).to be_success
      expect(result.value).to eq(num: 6)
      expect(result.operation).to be_an_instance_of(main_operation_klass)
      expect(result.ids).to eq([:result])
    end
  end

  describe ".on_failure" do
    let(:double_operation_klass) do
      Class.new(Fluxo::Operation(:num)) do
        def call!(**)
          Failure(:result) { "invalid number" }
        end
      end
    end

    let(:main_operation_klass) do
      Class.new(Fluxo::Operation(:num, :external)) do
        flow :double, :plus_one

        private

        def double(num:, external:, **)
          external.call(num: num)
        end

        def plus_one(num:, **)
          Success(num: num + 1)
        end
      end
    end

    it "coerces the value of sub operation to the main operation" do
      result = main_operation_klass.call(num: 2, external: double_operation_klass)
      expect(result).to be_failure
      expect(result.value).to eq("invalid number")
      expect(result.operation).to be_an_instance_of(main_operation_klass)
      expect(result.ids).to eq([:result])
    end
  end

  describe ".on_error" do
    let(:double_operation_klass) do
      Class.new(Fluxo::Operation(:num)) do
        def call!(**)
          raise ArgumentError
        end
      end
    end

    let(:main_operation_klass) do
      Class.new(Fluxo::Operation(:num, :external)) do
        flow :double, :plus_one

        private

        def double(num:, external:, **)
          external.call(num: num)
        end

        def plus_one(num:, **)
          Success(num: num + 1)
        end
      end
    end

    it "coerces the value of sub operation to the main operation" do
      result = main_operation_klass.call(num: 2, external: double_operation_klass)
      expect(result).to be_error
      expect(result.value).to be_an_instance_of(ArgumentError)
      expect(result.operation).to be_an_instance_of(main_operation_klass)
      expect(result.ids).to eq([:error])
    end
  end
end
