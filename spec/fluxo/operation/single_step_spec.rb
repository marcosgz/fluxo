require "spec_helper"

RSpec.describe "operation execution with a single step" do
  let(:operation) do
    Class.new(Fluxo::Operation) do
      attributes :a, :b
      def call!(a:, b:)
        return Failure(:a) { ":a must be different than zero" } if a == 0
        return Failure(":b must be different than zero") if b == 0

        a == 2 ? Success(:two) { a + b } : Success(a + b)
      end
    end
  end

  describe ".on_success" do
    specify do
      count = 0
      expected_value = nil
      operation
        .call(a: 2, b: 3)
        .on_success { |r| expected_value = r.value }
        .on_success { count += 1 }
        .on_success(:one) { count += 10 }
        .on_success(:two) { count += 20 }
        .on_failure { raise "on failure should not be called" }
        .on_error { raise "on error should not be called" }
      expect(count).to eq(21)
      expect(expected_value).to eq(5)
    end

    specify do
      count = 0
      expected_value = nil
      operation
        .call(a: 3, b: 3)
        .on_success { |r| expected_value = r.value }
        .on_success { count += 1 }
        .on_success(:one) { count += 10 }
        .on_success(:two) { count += 20 }
        .on_failure { raise "on failure should not be called" }
        .on_error { raise "on error should not be called" }
      expect(count).to eq(1)
      expect(expected_value).to eq(6)
    end
  end

  describe ".on_failure" do
    specify do
      count = 0
      operation
        .call(a: 0, b: 3)
        .on_failure { count += 1 }
        .on_failure(:a) { count += 10 }
        .on_failure(:b) { count += 20 }
        .on_success { raise " success hould not be called" }
        .on_error { raise "on error should not be called" }
      expect(count).to eq(11)
    end

    specify do
      count = 0
      operation
        .call(a: 3, b: 0)
        .on_failure { count += 1 }
        .on_failure(:a) { count += 10 }
        .on_failure(:b) { count += 20 }
        .on_success { raise "on success should not be called" }
        .on_error { raise "on error should not be called" }
      expect(count).to eq(1)
    end
  end

  describe ".on_error" do
    let(:operation) do
      Class.new(Fluxo::Operation) do
        attributes :exception
        def call!(exception:)
          raise exception
        end
      end
    end
    let(:exception) { StandardError.new("error") }

    specify do
      count = 0
      expected_value = nil
      expected_result = operation
        .call(exception: exception)
        .on_error { |r| expected_value = r.value }
        .on_error { count += 10 }
        .on_error(:something) { count += 20 }
        .on_success { raise "on success should not be called" }
        .on_failure { raise "on failure should not be called" }
      expect(count).to eq(10)
      expect(expected_value).to be(exception)
      expect(expected_result).to be_error
      expect(expected_result.value).to be(exception)
    end
  end
end
