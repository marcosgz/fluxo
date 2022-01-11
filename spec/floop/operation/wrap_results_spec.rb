require "spec_helper"

RSpec.describe "operation execution with a single step" do
  let(:falsey_operation) do
    Class.new(Floop::Operation) do
      def call!
        nil
      end
    end
  end

  let(:truthy_operation) do
    Class.new(Floop::Operation) do
      def call!
        1
      end
    end
  end

  context "when wrap_falsey_result is true" do
    before do
      Floop.config.wrap_falsey_result = true
    end

    after do
      reset_config!
    end

    it "should wrap the result in a Failure" do
      expect(result = falsey_operation.call).to be_failure
      expect(result.value).to eq(nil)
    end
  end

  context "when wrap_falsey_result is false" do
    before do
      Floop.config.wrap_falsey_result = false
    end

    after do
      reset_config!
    end

    it "should raise InvalidResultError" do
      expect { falsey_operation.call }.to raise_error(Floop::InvalidResultError)
    end
  end

  context "when wrap_truthy_result is true" do
    before do
      Floop.config.wrap_truthy_result = true
    end

    after do
      reset_config!
    end

    it "should wrap the result in a Success" do
      expect(result = truthy_operation.call).to be_success
      expect(result.value).to eq(1)
    end
  end

  context "when wrap_truthy_result is false" do
    before do
      Floop.config.wrap_truthy_result = false
    end

    after do
      reset_config!
    end

    it "should raise InvalidResultError" do
      expect { truthy_operation.call }.to raise_error(Floop::InvalidResultError)
    end
  end
end
