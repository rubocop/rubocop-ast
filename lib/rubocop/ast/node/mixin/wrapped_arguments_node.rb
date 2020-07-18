# frozen_string_literal: true

module RuboCop
  module AST
    # Common functionality for nodes that may have their arguments
    # wrapped in a `begin` node
    module WrappedArgumentsNode
      # @return [Array] The arguments of the node.
      def arguments
        first = children.first
        if first&.begin_type?
          first.children
        else
          children
        end
      end
    end
  end
end
