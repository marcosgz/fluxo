
module Floop
  module ActiveModelExtension
    module ClassMethods
      def validations(&block)
        @validations_proxy ||= build_validations_proxy!
        return unless block_given?

        begin
          @validations_proxy.class_eval(&block)
        rescue => e
          raise InvalidValidationsError, <<~ERROR
            Invalid validations for #{self.class.name}.

            #{e.message}
          ERROR
        end
      end

      private

      def build_validations_proxy!
        validator = Class.new do
          include ActiveModel::Validations

          def self.validate!(operation_instance)
            validator = new

            operation_instance.class.attribute_names.each do |attribute_name|
              validator.public_send(:"#{attribute_name}=", operation_instance.public_send(attribute_name))
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
          attr_accessor #{attribute_names.map(&:inspect).join(", ")}

          def self.model_name
            ::ActiveModel::Name.new(self, nil, %|#{name || "Anonymous"}|)
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
    include Floop::ActiveModelExtension
  end
end
