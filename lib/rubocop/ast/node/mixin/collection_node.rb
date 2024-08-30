# frozen_string_literal: true

module RuboCop
  module AST
    # A mixin that helps give collection nodes array polymorphism.
    module CollectionNode
      ARRAY_METHODS =
        (Array.instance_methods - Object.instance_methods - [:to_a]).freeze
      private_constant :ARRAY_METHODS

      ARRAY_METHODS.each do |method|
        class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          def #{method}(...)    # def key?(...)
            to_a.#{method}(...) #   to_a.key?(...)
          end                   # end
        RUBY
      end
    end
  end
end
