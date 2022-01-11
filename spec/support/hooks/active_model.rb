module Hooks
  module ActiveModel
    def self.included(base)
      base.around(:example) do |example|
        if example.metadata[:active_model] && !defined?(::ActiveModel)
          example.metadata[:skip] = "ActiveModel not defined"
        else
          example.run
        end
      end
    end
  end
end
