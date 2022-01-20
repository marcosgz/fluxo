require "spec_helper"

RSpec.describe "operation execution with a grouped flow steps" do
  describe ".on_success" do
    let(:operation_klass) do
      Class.new(Fluxo::Operation) do
        flow :add1, {inner_add: %i[add2 add3]}, :add4

        private

        def inner_add(**kwargs, &block)
          kwargs[:num] += 100
          block.call(**kwargs)
          nil
        end

        def sum(a, b)
          Success(num: a + b)
        end

        # rubocop:disable Style/SingleLineMethods,Layout/EmptyLineBetweenDefs
        def add1(num:); sum(num, 1); end
        def add2(num:); sum(num, 2); end
        def add3(num:); sum(num, 3); end
        def add4(num:); sum(num, 4); end
        # rubocop:enable Style/SingleLineMethods,Layout/EmptyLineBetweenDefs
      end
    end

    specify do
      expected_result = operation_klass.call(num: 0)
      expect(expected_result).to be_success
      expect(expected_result.value).to eq(num: 1 + 100 + 2 + 3 + 4)
    end
  end

  describe ".on_success" do
    let(:operation_klass) do
      Class.new(Fluxo::Operation) do
        flow :add1, {inner_add: %i[add2 add3]}, :add4

        private

        def inner_add(**kwargs, &block)
          kwargs[:num] += 100
          block.call(**kwargs)
          nil
        end

        def sum(a, b)
          Success(num: a + b)
        end

        # rubocop:disable Style/SingleLineMethods,Layout/EmptyLineBetweenDefs
        def add1(num:); sum(num, 1); end
        def add2(num:); Failure(-1); end
        def add3(num:); sum(num, 3); end
        def add4(num:); sum(num, 4); end
        # rubocop:enable Style/SingleLineMethods,Layout/EmptyLineBetweenDefs
      end
    end

    it "interrupts the execution right after grouped step fail" do
      expected_result = operation_klass.call(num: 0)
      expect(expected_result).to be_failure
      expect(expected_result.value).to eq(-1)
    end
  end

  describe ".on_error" do
    let(:operation_klass) do
      Class.new(Fluxo::Operation) do
        flow :add1, {inner_add: %i[add2 add3]}, :add4

        private

        def inner_add(**kwargs, &block)
          kwargs[:num] += 100
          block.call(**kwargs)
          nil
        end

        def sum(a, b)
          Success(num: a + b)
        end

        # rubocop:disable Style/SingleLineMethods,Layout/EmptyLineBetweenDefs
        def add1(num:); sum(num, 1); end
        def add2(num:); raise(RuntimeError); end
        def add3(num:); sum(num, 3); end
        def add4(num:); sum(num, 4); end
        # rubocop:enable Style/SingleLineMethods,Layout/EmptyLineBetweenDefs
      end
    end

    it "interrupts the execution right after grouped step fail" do
      expect { operation_klass.call(num: 0) }.to raise_error(RuntimeError)
      operation_klass.strict = false
      expected_result = operation_klass.call(num: 0)
      expect(expected_result).to be_error
      expect(expected_result.value).to be_an_instance_of(RuntimeError)
    end
  end

  describe "method attributes validation" do
    let(:operation_klass) do
      Class.new(Fluxo::Operation) do
        flow :step1, {group: %i[step2 step3]}, :step4

        private

        def group(**kwargs, &block)
          block.call(**kwargs)
          nil
        end

        # rubocop:disable Style/SingleLineMethods,Layout/EmptyLineBetweenDefs
        def step1(foo:); Success(bar: "ok"); end
        def step2(bar:, **); Void(); end
        def step3(foo:, bar:); Void(); end
        def step4(foo:, **); Success(:ok); end
        # rubocop:enable Style/SingleLineMethods,Layout/EmptyLineBetweenDefs
      end
    end

    it "does not validate attributes method identity on grouped steps" do
      expect { operation_klass.call(foo: "ok") }.not_to raise_error
    end
  end

  context "when groups adds transient data to the operation" do
    let(:operation_klass) do
      Class.new(Fluxo::Operation) do
        flow :a, {group: %i[b c]}, :d

        private

        def group(**kwargs, &block)
          block.call(**kwargs)
        end

        # rubocop:disable Style/SingleLineMethods,Layout/EmptyLineBetweenDefs
        def a(a:); Success(b: a.to_s); end
        def b(a:, b:); Success(c: b.to_s, d: "ok"); end
        def c(a:, b:, c:, d:); Void(); end
        def d(d:, **); Success("#{d} from #d"); end
        # rubocop:enable Style/SingleLineMethods,Layout/EmptyLineBetweenDefs
      end
    end

    specify do
      expected_result = operation_klass.call(a: :a)
      expect(expected_result).to be_success
      expect(expected_result.value).to eq("ok from #d")
    end
  end
end
