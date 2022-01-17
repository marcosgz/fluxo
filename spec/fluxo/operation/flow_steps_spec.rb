require "spec_helper"

RSpec.describe "operation execution with a flow" do
  describe ".on_success" do
    let(:operation_klass) do
      Class.new(Fluxo::Operation(:num)) do
        flow :add1, :add2

        private

        def add1(num:, **)
          Success(:one) { {num: num + 1} }
        end

        def add2(num:, **)
          Success(num: num + 2)
        end
      end
    end

    it "calls the global on_success only once with updated value from all flow steps" do
      count = 0
      expected_value = nil
      result = operation_klass
        .call(num: 0)
        .on_success { |r| expected_value = r.value }
        .on_success { count += 1 }
        .on_success(:one) { count += 10 }
        .on_success(:two) { count += 20 }
        .on_failure { raise "on failure should not be called" }
        .on_error { raise "on error should not be called" }
      expect(result).to be_success
      expect(count).to eq(11)
      expect(expected_value).to eq(num: 3)
    end
  end

  describe ".on_failure" do
    let(:operation_klass) do
      Class.new(Fluxo::Operation(:num)) do
        flow :add1, :add2, :add3

        private

        def add1(num:, **)
          Success(:one) { {num: num + 1} }
        end

        def add2(num:, **)
          Failure(:two) { {num: num + 2} }
        end

        def add3(num:, **)
          Failure(num: num + 3)
        end
      end
    end

    it "calls the global on_failure only once with a result of all flow steps" do
      count = 0
      expected_value = nil
      operation_klass
        .call(num: 0)
        .on_failure { |r| expected_value = r.value }
        .on_failure { count += 1 }
        .on_failure(:one) { count += 10 }
        .on_failure(:two) { count += 20 }
        .on_success { raise }
        .on_error { raise }
      expect(count).to eq(21)
      expect(expected_value).to eq(num: 3)
    end
  end

  describe ".on_error" do
    let(:operation_klass) do
      Class.new(Fluxo::Operation(:num)) do
        flow :add1, :add2, :add3

        private

        def add1(num:, **)
          Success(:one) { {num: num + 1} }
        end

        def add2(num:, **)
          raise NoMethodError
        end

        def add3(num:, **)
          raise "error"
        end
      end
    end

    it "calls the global on_error only once with a result of all flow steps" do
      count = 0
      expected_value = nil
      expected_result = operation_klass
        .call(num: 0)
        .on_error { |r| expected_value = r.value }
        .on_error { count += 1 }
        .on_error(:something) { count += 10 }
        .on_success { raise "on success should not be called" }
      expect(count).to eq(1)
      expect(expected_value).to be_an_instance_of(NoMethodError)
      expect(expected_result.value).to be_an_instance_of(NoMethodError)
    end
  end
end
