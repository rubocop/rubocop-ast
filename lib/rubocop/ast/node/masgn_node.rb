# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `masgn` nodes.
    # This will be used in place of a plain node when the builder constructs
    # the AST, making its methods available to all assignment nodes within RuboCop.
    class MasgnNode < Node
      # @return [MlhsNode] the `mlhs` node
      def lhs
        # The first child is a `mlhs` node
        node_parts[0]
      end

      # @return [Array<Node>] the assignment nodes of the multiple assignment
      def assignments
        lhs.assignments
      end

      # @return [Array<Symbol>] names of all the variables being assigned
      def names
        assignments.map do |assignment|
          if assignment.send_type? || assignment.indexasgn_type?
            assignment.source
          else
            assignment.name
          end
        end
      end

      # The expression being assigned to the variable.
      #
      # @return [Node] the expression being assigned.
      def expression
        node_parts[1]
      end
      alias rhs expression

      # @return [Array<Node>] values being assigned on the RHS of the multiple assignment
      def values
        array? ? expression.children : [expression]
      end

      # @return [Boolean] whether the expression has multiple values
      def array?
        expression.array_type?
      end
    end
  end
end
