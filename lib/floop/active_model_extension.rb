
module Floop
  class Validations
    include ActiveModel::Validations

    def initialize(operation)
      @operation = operation
      operation.attribute_names.each do |attribute|
        define_method attribute do
          @operation.send(attribute)
        end
      end
    end

    def valid?
      super
      errors.empty?
    end
  end

  module ActiveModelExtension
    module ClassMethods
      attr_reader :validations_instance

      def validations(&block)
        @validations_instance = Validations.new(self).instance_eval(&block)
      end
    end

    module InstanceMethods
    end

    def self.included(klass)
      klass.extend(ClassMethods)
      klass.send(:include, InstanceMethods)
    end
  end

  class Operation
    include Floop::ActiveModelExtension
  end
end
