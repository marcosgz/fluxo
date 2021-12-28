# frozen_string_literal: true

module Floop
  class Operation
    module Attributes
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      module ClassMethods
        def attribute_names
          @attribute_names ||= []
        end

        def attributes(*names)
          @attribute_names ||= []
          names = names.map(&:to_sym) - @attribute_names
          @attribute_names.push(*names)

          names.each do |key|
            define_method key do
              instance_variable_get(:"@#{key}")
            end
          end
        end

        def attribute?(key)
          return false unless key

          attribute_names.include?(key.to_sym)
        end
      end
    end
  end
end
