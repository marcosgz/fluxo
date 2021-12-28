# frozen_string_literal: true

module Floop
  class Operation
    module Constructor
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      module ClassMethods
        def def_Operation(op_module)
          tap do |klass|
            op_module.define_singleton_method(:Operation) do |*attrs|
              klass.Operation(*attrs)
            end
          end
        end

        def Operation(*attrs)
          Class.new(self).tap do |klass|
            klass.attributes(*attrs)
          end
        end
      end
    end
  end
end
