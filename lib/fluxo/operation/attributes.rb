# frozen_string_literal: true

module Fluxo
  class Operation
    module Attributes
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      module ClassMethods
        # This variable is used only when ActiveModel is available.
        attr_reader :validations_proxy

        # Auto handle errors/exceptions.
        attr_writer :strict

        def strict?
          return @strict if defined? @strict

          @strict = Fluxo.config.strict?
        end

        def validations
          raise NotImplementedError, "ActiveModel is not defined to use validations."
        end
      end
    end
  end
end
