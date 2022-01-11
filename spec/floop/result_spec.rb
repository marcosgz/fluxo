require "spec_helper"

RSpec.describe Floop::Result do
  let(:ids) { nil }
  let(:value) { 1 }
  let(:type) { :ok }
  let(:operation) { instance_double(Floop::Operation) }
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
      it { expect { |b| model.on_failure(:bar, &b) }.not_to yield_control }
      it { expect { |b| model.on_success(:foo, &b) }.not_to yield_control }
      it { expect { |b| model.on_error(:foo, &b) }.not_to yield_control }
    end
  end
end
