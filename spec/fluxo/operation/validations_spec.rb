require "spec_helper"

RSpec.describe "operation validations" do
  shared_examples "validations" do
    context "when validations are valid" do
      specify do
        expect(operation.call(name: "John", age: 20)).to be_success
      end
    end

    context "when validations are invalid" do
      specify do
        expect(result = operation.call(name: nil, age: 20)).to be_failure
        expect(result.value).to be_an_instance_of(ActiveModel::Errors)
      end

      specify do
        count = 0
        operation
          .call(name: "John", age: 17)
          .on_failure { count += 1 }
          .on_failure(:validation) { count += 10 }
          .on_failure(:something_else) { count += 20 }
          .on_success { raise " success hould not be called" }
          .on_error { raise "on error should not be called" }
        expect(count).to eq(11)
      end
    end
  end

  describe "with validation of ", active_model: true do
    let(:operation) do
      Class.new(Fluxo::Operation) do
        flow :step1, :step2, {group: %i[step3 step4]}, :step5

        validations do
          validates :foo, presence: true
        end

        private

        def group(**kwargs, &block)
          block.call(**kwargs)
          nil
        end

        # rubocop:disable Style/SingleLineMethods,Layout/EmptyLineBetweenDefs
        def step1(foo:); Success(bar: "ok"); end
        def step2(bar:, **); Void(); end
        def step3(foo:, **); Void(); end
        def step4(bar:, **); Void(); end
        def step5(foo:, **); Success(:ok); end
        # rubocop:enable Style/SingleLineMethods,Layout/EmptyLineBetweenDefs
      end
    end

    it "does not execute validation on grouped flow steps" do
      expect(operation.call(foo: "test")).to be_success
    end
  end

  describe "with one validation block", active_model: true do
    let(:operation) do
      Class.new(Fluxo::Operation) do
        validations do
          validates :name, presence: true
          validates :age, numericality: {greater_than: 18}
        end

        def call!(**)
          Success(:ok)
        end
      end
    end

    include_examples "validations"
  end

  context "when multiple validations blocks", active_model: true do
    let(:operation) do
      Class.new(Fluxo::Operation) do
        validations do
          validates :name, presence: true
        end

        validations do
          validates :age, numericality: {greater_than: 18}
        end

        def call!(**)
          Success(:ok)
        end
      end
    end

    include_examples "validations"
  end

  context "when active model is not available", active_model: false do
    let(:operation) do
      Class.new(Fluxo::Operation) do
        validations do
          validates :name, presence: true
          validates :age, numericality: {greater_than: 18}
        end

        def call!(**)
          Success(:ok)
        end
      end
    end

    specify do
      expect { operation.call(name: "John", age: 20) }.to raise_error(NotImplementedError)
    end
  end
end
