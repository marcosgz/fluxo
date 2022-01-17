require "spec_helper"

RSpec.describe "operation execution with a grouped flow steps" do
  describe ".on_success" do
    let(:operation_klass) do
      Class.new(Fluxo::Operation(:num)) do
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
      Class.new(Fluxo::Operation(:num)) do
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
      Class.new(Fluxo::Operation(:num)) do
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
        def add2(num:); raise(ArgumentError); end
        def add3(num:); sum(num, 3); end
        def add4(num:); sum(num, 4); end
        # rubocop:enable Style/SingleLineMethods,Layout/EmptyLineBetweenDefs
      end
    end

    it "interrupts the execution right after grouped step fail" do
      expected_result = operation_klass.call(num: 0)
      expect(expected_result).to be_error
      expect(expected_result.value).to be_an_instance_of(ArgumentError)
    end
  end
end