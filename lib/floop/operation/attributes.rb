# frozen_string_literal: true

module Floop
  class Operation
    module Attributes
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      module ClassMethods
        attr_reader :validations_proxy

        # When set to true, the operation will not validate the transient_attributes defition during the flow step execution.
        attr_writer :sloppy_transient_attributes

        # When set to true, the operation will not validate attributes definition before calling the operation.
        attr_writer :sloppy_attributes

        def sloppy_attributes?
          return @sloppy_attributes if defined?(@sloppy_attributes)

          Floop.config.sloppy_attributes
        end

        def sloppy_transient_attributes?
          return @sloppy_transient_attributes if defined?(@sloppy_transient_attributes)

          Floop.config.sloppy_transient_attributes
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
