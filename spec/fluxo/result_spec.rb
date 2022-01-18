require "spec_helper"

RSpec.describe Fluxo::Result do
  let(:ids) { nil }
  let(:value) { 1 }
  let(:type) { :ok }
  let(:operation) { instance_double(Fluxo::Operation) }
  let(:attrs) do
    {operation: operation, type: type, value: value, ids: ids}
  end

  describe ".success?" do
    it { expect(described_class.new(**attrs.merge(type: :ok))).to be_success }
    it { expect(described_class.new(**attrs.merge(type: :exception))).not_to be_success }
    it { expect(described_class.new(**attrs.merge(type: :failure))).not_to be_success }
  end

  describe ".error?" do
    it { expect(described_class.new(**attrs.merge(type: :ok))).not_to be_error }
    it { expect(described_class.new(**attrs.merge(type: :exception))).to be_error }
    it { expect(described_class.new(**attrs.merge(type: :failure))).not_to be_error }
  end

  describe ".failure?" do
    it { expect(described_class.new(**attrs.merge(type: :ok))).not_to be_failure }
    it { expect(described_class.new(**attrs.merge(type: :exception))).not_to be_failure }
    it { expect(described_class.new(**attrs.merge(type: :failure))).to be_failure }
  end

  describe "hooks" do
    context "with :ok type" do
      let(:model) { described_class.new(**attrs) }

      it { expect { |b| model.on_success(&b) }.to yield_with_args(model) }
      it { expect { |b| model.on_failure(&b) }.not_to yield_control }
      it { expect { |b| model.on_error(&b) }.not_to yield_control }
    end

    context "with :ok type and ids" do
      let(:ids) { %i[foo] }
      let(:model) { described_class.new(**attrs) }

      it { expect { |b| model.on_success(:foo, &b) }.to yield_with_args(model) }
      it { expect { |b| model.on_success(:foo, :bar, &b) }.to yield_with_args(model) }
      it { expect { |b| model.on_success(:bar, &b) }.not_to yield_control }
      it { expect { |b| model.on_failure(:foo, &b) }.not_to yield_control }
      it { expect { |b| model.on_error(:foo, &b) }.not_to yield_control }
    end

    context "with :exception type" do
      let(:type) { :exception }
      let(:model) { described_class.new(**attrs) }

      it { expect { |b| model.on_error(&b) }.to yield_with_args(model) }
      it { expect { |b| model.on_failure(&b) }.not_to yield_control }
      it { expect { |b| model.on_success(&b) }.not_to yield_control }
    end

    context "with :exception type and ids" do
      let(:ids) { %i[foo] }
      let(:type) { :exception }
      let(:model) { described_class.new(**attrs) }

      it { expect { |b| model.on_error(:foo, &b) }.to yield_with_args(model) }
      it { expect { |b| model.on_error(:foo, :bar, &b) }.to yield_with_args(model) }
      it { expect { |b| model.on_failure(:bar, &b) }.not_to yield_control }
      it { expect { |b| model.on_failure(:foo, &b) }.not_to yield_control }
      it { expect { |b| model.on_success(:foo, &b) }.not_to yield_control }
    end

    context "with :failure type" do
      let(:type) { :failure }
      let(:model) { described_class.new(**attrs) }

      it { expect { |b| model.on_failure(&b) }.to yield_with_args(model) }
      it { expect { |b| model.on_success(&b) }.not_to yield_control }
      it { expect { |b| model.on_error(&b) }.not_to yield_control }
    end

    context "with :failure type and ids" do
      let(:ids) { %i[foo] }
      let(:type) { :failure }
      let(:model) { described_class.new(**attrs) }

      it { expect { |b| model.on_failure(:foo, &b) }.to yield_with_args(model) }
      it { expect { |b| model.on_failure(:foo, :bar, &b) }.to yield_with_args(model) }
      it { expect { |b| model.on_failure(:bar, &b) }.not_to yield_control }
      it { expect { |b| model.on_success(:foo, &b) }.not_to yield_control }
      it { expect { |b| model.on_error(:foo, &b) }.not_to yield_control }
    end
  end

  describe "#mutate" do
    let(:model) { described_class.new(**attrs) }
    let(:new_value) { 2 }
    let(:new_type) { :failure }
    let(:new_ids) { %i[foo] }
    let(:new_operation) { instance_double(Fluxo::Operation) }

    it "returns a new model with the new attributes" do
      expect(model.mutate(operation: new_operation, value: new_value, type: new_type, ids: new_ids)).to eq(
        described_class.new(
          operation: new_operation,
          type: new_type,
          value: new_value,
          ids: new_ids
        )
      )
    end

    it "returns a new model with modified operation" do
      expect(model.mutate(operation: new_operation)).to eq(
        described_class.new(
          operation: new_operation,
          type: model.type,
          value: model.value,
          ids: model.ids
        )
      )
    end

    it "returns a new model with modified type" do
      expect(model.mutate(type: new_type)).to eq(
        described_class.new(
          operation: model.operation,
          type: new_type,
          value: model.value,
          ids: model.ids
        )
      )
    end

    it "returns a new model with modified value" do
      expect(model.mutate(value: new_value)).to eq(
        described_class.new(
          operation: model.operation,
          type: model.type,
          value: new_value,
          ids: model.ids
        )
      )
    end

    it "returns a new model with modified ids" do
      expect(model.mutate(ids: new_ids)).to eq(
        described_class.new(
          operation: model.operation,
          type: model.type,
          value: model.value,
          ids: new_ids
        )
      )
    end
  end
end
