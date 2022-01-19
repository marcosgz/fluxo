require 'ostruct'

module Fluxo
  module ActiveModelExtension
    module ClassMethods
      def validations(&block)
        @validations_proxy ||= build_validations_proxy!
        return unless block_given?

        begin
          @validations_proxy.class_eval(&block)
        rescue => e
          raise ValidationDefinitionError, <<~ERROR
            Invalid validations for #{self.class.name}.

            #{e.message}
          ERROR
        end
      end

      private

      def build_validations_proxy!
        validator = Class.new(OpenStruct) do
          include ActiveModel::Validations

          def self.validate!(operation_instance, **attrs)
            validator = new

            attrs.each do |name, value|
              validator.public_send(:"#{name}=", value)
            end

            if validator.valid?
              operation_instance.Void()
            else
              operation_instance.Failure(:validation) { validator.errors }
            end
          end

          def valid?
            super
            errors.empty?
          end
        end

        validator.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def self.name
            "#{name || 'Fluxo::Operation'}::Validations"
          end

          def self.to_s
            name
          end
        RUBY

        validator
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
    include Fluxo::ActiveModelExtension
  end
end
