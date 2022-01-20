require "spec_helper"
require "fluxo/rspec"

class DummyFlowOperation < Fluxo::Operation
  flow :success, :failure, :error

  def success(**arguments)
    Success(:success) { arguments }
  end

  def failure(**arguments)
    Failure(:failure) { arguments }
  end

  def error(err: nil, **arguments)
    raise err || "error"
  end
end

RSpec.describe DummyFlowOperation, type: :operation do
  before do
    described_class.strict = true
  end

  describe "#expect_step_result and #step_result" do
    specify do
      allow_any_instance_of(described_class).to receive(:success).and_call_original
      expect_step_result(:success).to be_an_instance_of(Fluxo::Result)
      expect(result).to be_success
    end

    specify do
      allow_any_instance_of(described_class).to receive(:success).with(success: "ok").and_call_original
      expect_step_result(:success, success: "ok").to be_an_instance_of(Fluxo::Result)
      expect(result).to be_success
    end

    specify do
      allow_any_instance_of(described_class).to receive(:failure).with(failure: "fail").and_call_original
      expect_step_result(:failure, failure: "fail").to be_an_instance_of(Fluxo::Result)
      expect(result).to be_failure
    end

    specify do
      allow_any_instance_of(described_class).to receive(:error).with(err: "err").and_call_original
      expect { step_result(:error, err: "err") }.to raise_error(RuntimeError)
    end

    specify do
      allow_any_instance_of(described_class).to receive(:error).with(err: "err").and_call_original

      described_class.strict = false
      expect { step_result(:error, err: "err")  }.to_not raise_error
      expect(result).to be_error
    end
  end
end
