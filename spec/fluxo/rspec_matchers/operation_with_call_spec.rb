require "spec_helper"
require "fluxo/rspec"

class DummySingleCallOperation < Fluxo::Operation
  def call!(failure: nil, success: nil, error: nil)
    if failure
      Failure(:failure) { failure }
    elsif success
      Success(:success) { success }
    elsif error
      raise error
    else
      Success(:success) { :ok }
    end
  end
end

RSpec.describe DummySingleCallOperation, type: :operation do
  before do
    described_class.strict = true
  end

  describe ".call" do
    it "returns a success result" do
      result = described_class.call
      expect(result).to be_success
      expect(result.value).to eq(:ok)
    end

    it "returns a failure result" do
      result = described_class.call(failure: "failure")
      expect(result).to be_failure
      expect(result.value).to eq("failure")
    end

    it "returns an error result" do
      expect {
        described_class.call(error: "error")
      }.to raise_error(RuntimeError, "error")
      described_class.strict = false
      result = described_class.call(error: "error")
      expect(result).to be_error
      expect(result.value).to be_an_instance_of(RuntimeError)
    end
  end

  describe "#expect_operation_result and #operation_result" do
    specify do
      expect(described_class).to receive(:call).and_call_original
      expect_operation_result.to be_an_instance_of(Fluxo::Result)
      expect(result).to be_success
    end

    specify do
      expect(described_class).to receive(:call).with(success: "ok").and_call_original
      expect_operation_result(success: "ok").to be_an_instance_of(Fluxo::Result)
      expect(result).to be_success
    end

    specify do
      expect(described_class).to receive(:call).with(failure: "fail").and_call_original
      expect_operation_result(failure: "fail").to be_an_instance_of(Fluxo::Result)
      expect(result).to be_failure
    end

    specify do
      expect(described_class).to receive(:call).with(error: "err").and_call_original
      expect { operation_result(error: "err") }.to raise_error(RuntimeError)
    end

    specify do
      expect(described_class).to receive(:call).with(error: "err").and_call_original

      described_class.strict = false
      expect { operation_result(error: "err") }.to_not raise_error
      expect(result).to be_error
    end
  end

  describe "#expect_step_result and #step_result" do
    specify do
      allow_any_instance_of(described_class).to receive(:call!).and_call_original
      expect_step_result(:call!).to be_an_instance_of(Fluxo::Result)
      expect(result).to be_success
    end

    specify do
      allow_any_instance_of(described_class).to receive(:call!).with(success: "ok").and_call_original
      expect_step_result(:call!, success: "ok").to be_an_instance_of(Fluxo::Result)
      expect(result).to be_success
    end

    specify do
      allow_any_instance_of(described_class).to receive(:call!).with(failure: "fail").and_call_original
      expect_step_result(:call!, failure: "fail").to be_an_instance_of(Fluxo::Result)
      expect(result).to be_failure
    end

    specify do
      allow_any_instance_of(described_class).to receive(:call!).with(error: "err").and_call_original
      expect { step_result(:call!, error: "err") }.to raise_error(RuntimeError)
    end

    specify do
      allow_any_instance_of(described_class).to receive(:call!).with(error: "err").and_call_original

      described_class.strict = false
      expect { step_result(:call!, error: "err") }.to_not raise_error
      expect(result).to be_error
    end
  end

  describe "result_succeed matcher" do
    specify do
      expect(described_class.call).to result_succeed
    end

    specify do
      expect(described_class.call(success: "ok")).to result_succeed.with_value("ok")
    end

    send(ENV["MATCHER_FAILURES"] == "true" ? :fcontext : :skip, "testing matcher failures") do
      specify do
        expect(described_class.call(success: "ok")).to result_succeed.with_value("other")
      end

      specify do
        expect(described_class.call(failure: "fail")).to result_succeed
      end

      specify do
        expect(described_class.call(failure: "fail")).to result_succeed.with_value("ok")
      end

      specify do
        described_class.strict = false
        expect(described_class.call(error: "err")).to result_succeed
      end
    end
  end

  describe "result_fail matcher" do
    specify do
      expect(described_class.call(failure: "fail")).to result_fail
    end

    specify do
      expect(described_class.call(failure: "fail")).to result_fail.with_value("fail")
    end

    send(ENV["MATCHER_FAILURES"] == "true" ? :fcontext : :skip, "testing matcher failures") do
      specify do
        expect(described_class.call(success: "ok")).to result_fail
      end

      specify do
        expect(described_class.call(success: "ok")).to result_fail.with_value("fail")
      end

      specify do
        expect(described_class.call(failure: "fail")).to result_fail.with_value("other")
      end

      specify do
        described_class.strict = false
        expect(described_class.call(error: "err")).to result_fail
      end

      specify do
        described_class.strict = false
        expect(described_class.call(error: "err")).to result_fail.with_value("fail")
      end
    end
  end

  describe "result_error matcher" do
    specify do
      described_class.strict = false
      expect(described_class.call(error: "err")).to result_error
    end

    specify do
      described_class.strict = false
      expect(described_class.call(error: "err")).to result_error.with_value(RuntimeError)
    end

    send(ENV["MATCHER_FAILURES"] == "true" ? :fcontext : :skip, "testing matcher failures") do
      specify do
        expect(described_class.call(success: "ok")).to result_error
      end

      specify do
        expect(described_class.call(success: "ok")).to result_error.with_value(RuntimeError)
      end

      specify do
        expect(described_class.call(failure: "fail")).to result_error
      end

      specify do
        expect(described_class.call(failure: "fail")).to result_error.with_value(RuntimeError)
      end

      specify do
        described_class.strict = false
        expect(described_class.call(error: "err")).to result_error.with_value(StandardError.new("other"))
      end
    end
  end
end
