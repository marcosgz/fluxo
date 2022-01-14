# frozen_string_literal: true

module Fluxo
  class Operation
    module Attributes
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      module ClassMethods
        attr_reader :validations_proxy

        # When set to true, the operation will not validate the transient_attributes defition during the flow step execution.
        attr_writer :strict_transient_attributes

        # When set to true, the operation will not validate attributes definition before calling the operation.
        attr_writer :strict_attributes

        def strict_attributes?
          return @strict_attributes if defined?(@strict_attributes)

          Fluxo.config.strict_attributes
        end

        def strict_transient_attributes?
          return @strict_transient_attributes if defined?(@strict_transient_attributes)

          Fluxo.config.strict_transient_attributes
        end

        def validations
          raise NotImplementedError, "ActiveModel is not defined to use validations."
        end

        def attribute_names
          @attribute_names ||= []
        end

        def transient_attribute_names
          @transient_attribute_names ||= []
        end

        def attributes(*names)
          @attribute_names ||= []
          names = names.map(&:to_sym) - @attribute_names
          @attribute_names.push(*names)
        end

        def transient_attributes(*names)
          @transient_attribute_names ||= []
          names = names.map(&:to_sym) - @transient_attribute_names
          @transient_attribute_names.push(*names)
        end

        def attribute?(key)
          return false unless key

          attribute_names.include?(key.to_sym)
        end

        def transient_attribute?(key)
          return false unless key

          transient_attribute_names.include?(key.to_sym)
        end
      end
    end
  end
end
