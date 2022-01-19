require "spec_helper"

RSpec.describe "operation error handlers" do
  describe ".on_error" do
    let(:operation_class) do
      Class.new(Fluxo::Operation) do
        def call!
          raise StandardError, "internal error"
        end
      end
    end

    let(:error_handler) { double("error handler") }

    before do
      expect(error_handler).to receive(:call).with(Fluxo::Result)
      Fluxo.config do |config|
        config.error_handlers << error_handler
      end
    end

    after do
      Fluxo.config do |config|
        config.error_handlers.clear
      end
    end

    it "calls the error handlers by running on strict mode" do
      operation_class.strict = true
      expect { operation_class.call }.to raise_error(StandardError)
    end

    it "calls the error handlers by running on non-strict mode" do
      operation_class.strict = false
      expect(operation_class.call).to be_error
    end
  end
end
