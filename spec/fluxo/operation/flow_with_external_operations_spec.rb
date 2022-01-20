require "spec_helper"

RSpec.describe "operation execution with a flow with external operation result" do
  describe ".on_success" do
    let(:double_operation_klass) do
      Class.new(Fluxo::Operation) do
        def call!(num:)
          Success(:result) { {num: num * 2} }
        end
      end
    end

    let(:main_operation_klass) do
      Class.new(Fluxo::Operation) do
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
      Class.new(Fluxo::Operation) do
        def call!(**)
          Failure(:result) { "invalid number" }
        end
      end
    end

    let(:main_operation_klass) do
      Class.new(Fluxo::Operation) do
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
      Class.new(Fluxo::Operation) do
        def call!(**)
          raise RuntimeError, "invalid number"
        end
      end
    end

    let(:main_operation_klass) do
      Class.new(Fluxo::Operation) do
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
      expect {
        main_operation_klass.call(num: 2, external: double_operation_klass)
      }.to raise_error(RuntimeError)

      double_operation_klass.strict = false
      result = main_operation_klass.call(num: 2, external: double_operation_klass)
      expect(result).to be_error
      expect(result.value).to be_an_instance_of(RuntimeError)
      expect(result.operation).to be_an_instance_of(main_operation_klass)
      expect(result.ids).to eq([:error])
    end
  end

  context "when external operation result does not match with the flow data data" do
    let(:double_operation_klass) do
      Class.new(Fluxo::Operation) do
        def call!(number:)
          Success(number * 2)
        end
      end
    end

    let(:main_operation_klass) do
      Class.new(Fluxo::Operation) do
        flow :skip, :double, :skip, :num_plus_double

        private

        def double(num:, external:, **)
          external
            .call(number: num)
            .on_success { |result| return Success(double_result: result.value) }
        end

        def skip(**)
          Void()
        end

        def num_plus_double(num:, double_result:, **)
          Success(num: num + double_result)
        end
      end
    end

    it "preserves transitent data from previous flow operations" do
      result = main_operation_klass.call(num: 2, external: double_operation_klass)
      expect(result).to be_success
      expect(result.value).to eq(num: 6)
    end
  end
end
