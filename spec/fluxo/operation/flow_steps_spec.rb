require "spec_helper"

RSpec.describe "operation execution with a flow" do
  describe ".on_success" do
    context "when operation only mutate attributes" do
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

    context "when operation wraps the value of last step to a non-hash object" do
      let(:operation_klass) do
        Class.new(Fluxo::Operation(:num)) do
          flow :parse, :double_and_wrap

          private

          def parse(num:, **)
            Success(num: num.to_i)
          end

          def double_and_wrap(num:, **)
            Success(num * 2)
          end
        end
      end

      it "executes all steps and return the value of last step as the Result value" do
        result = operation_klass.call(num: "2")
        expect(result).to be_success
        expect(result.value).to eq(4)
      end
    end

    context "when operation uses transient attributes" do
      let(:operation_klass) do
        Class.new(Fluxo::Operation(:num)) do
          flow :add1, :wrap
          transient_attributes :total

          private

          def add1(num:, **)
            Success(:one) { {total: num + 1} }
          end

          def wrap(total:, **)
            Success(total: total)
          end
        end
      end

      it "passes transient attributes to the flow steps" do
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
        expect(expected_value).to eq(total: 1)
      end

      it "raises an error when step does not have defined transient attributes running on strict mode" do
        opp_class = Class.new(Fluxo::Operation(:num)) do
          flow :add1, :wrap

          def add1(num:, **)
            Success(:one) { {total: num + 1} }
          end

          def wrap(total:, num:, **)
            Success(total: total * num)
          end
        end
        expect { opp_class.call(num: 2) }.to raise_error(Fluxo::NotDefinedAttributeError)
        opp_class.strict_transient_attributes = false
        expect(result = opp_class.call(num: 2)).to be_success
        expect(result.value).to eq(total: 6)
      end
    end
  end

  describe ".on_failure" do
    context "when operation only mutates attributes" do
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

    context "when operation uses transient attributes" do
      it "raises an error when step does not have defined transient attributes running on strict mode" do
        opp_class = Class.new(Fluxo::Operation(:num)) do
          flow :add1, :wrap

          def add1(num:, **)
            Success(:one) { {total: num + 1} }
          end

          def wrap(total:, **)
            Failure(total: total)
          end
        end
        expect { opp_class.call(num: 0) }.to raise_error(Fluxo::NotDefinedAttributeError)
        opp_class.strict_transient_attributes = false
        expect(result = opp_class.call(num: 0)).to be_failure
        expect(result.value).to eq(total: 1)
      end
    end
  end

  describe ".on_error" do
    context "when operation only mutates attributes" do
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

    context "when operation uses transient attributes" do
      it "raises an error when step does not have defined transient attributes running on strict mode" do
        opp_class = Class.new(Fluxo::Operation(:num)) do
          flow :add1, :wrap

          def add1(num:, **)
            Success(:one) { {total: num + 1} }
          end

          def wrap(total:, **)
            raise NoMethodError
          end
        end
        expect { opp_class.call(num: 0) }.to raise_error(Fluxo::NotDefinedAttributeError)
        opp_class.strict_transient_attributes = false
        expect(result = opp_class.call(num: 0)).to be_error
        expect(result.value).to be_an_instance_of(NoMethodError)
      end
    end
  end
end
