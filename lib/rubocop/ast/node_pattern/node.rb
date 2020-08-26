# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      # Base class for AST Nodes of a `NodePattern`
      class Node < ::Parser::AST::Node
        extend Forwardable
        include ::RuboCop::AST::Descendence

        ###
        # To be overriden by subclasses
        ###

        def rest?
          false
        end

        def capture?
          false
        end

        # @return [Integer, Range] An Integer for fixed length terms, otherwise a Range.
        # Note: `arity.end` may be `Float::INFINITY`
        def arity
          1
        end

        # Return [Symbol] either :ok, :raise, or :insert_wildcard
        def in_sequence_head
          :ok
        end

        ###
        # Utilities
        ###

        # @return [Array<Node>]
        def children_nodes
          children.grep(Node)
        end

        # @return [Node] most nodes have only one child
        def child
          children[0]
        end

        # @return [Integer] nb of captures of that node and its descendants
        def nb_captures
          children_nodes.sum(&:nb_captures)
        end

        # @return [Boolean] returns true iff matches variable number of elements
        def variadic?
          arity.is_a?(Range)
        end

        # @return [Range] arity as a Range
        def arity_range
          a = arity
          a.is_a?(Range) ? a : INT_TO_RANGE[a]
        end

        INT_TO_RANGE = Hash.new { |h, k| h[k] = k..k }
        private_constant :INT_TO_RANGE

        ###
        # Subclasses for specific node types
        ###

        # Registry
        MAP = Hash.new(Node)
        def self.setup_registry
          %i[sequence repetition rest capture predicate any_order function_call].each do |type|
            MAP[type] = const_get(type.to_s.gsub(/(_|^)(.)/) { Regexp.last_match(2).upcase })
          end
          MAP.freeze
        end

        # Node class for `$something`
        class Capture < Node
          # Delegate most introspection methods to it's only child
          def_delegators :child, :arity, :rest?, :in_sequence_head

          def capture?
            true
          end

          def nb_captures
            1 + super
          end
        end

        # Node class for `(type first second ...)`
        class Sequence < Node
          def initialize(type, children = [], properties = {})
            case children.first.in_sequence_head
            when :insert_wildcard
              children = [Node.new(:wildcard), *children]
            when :raise
              raise NodePattern::Invalid, "A sequence can not start with #{children.first}"
            end

            super
          end

          def in_sequence_head
            :raise
          end
        end

        # Node class for `predicate?(:arg, :list)`
        class Predicate < Node
          def method_name
            children.first
          end

          def arg_list
            children[1..-1]
          end
        end
        FunctionCall = Predicate

        # Node class for `int+`
        class Repetition < Node
          def operator
            children[1]
          end

          ARITIES = {
            '*': 0..Float::INFINITY,
            '+': 1..Float::INFINITY,
            '?': 0..1
          }.freeze

          def arity
            ARITIES[operator]
          end

          def in_sequence_head
            :raise
          end
        end

        # Node class for `...`
        class Rest < Node
          ARITY = (0..Float::INFINITY).freeze
          private_constant :ARITY

          def rest?
            true
          end

          def arity
            ARITY
          end

          def in_sequence_head
            :insert_wildcard
          end
        end

        # Node class for `<int str ...>`
        class AnyOrder < Node
          ARITIES = Hash.new { |h, k| h[k] = k - 1..Float::INFINITY }
          private_constant :ARITIES

          def term_nodes
            ends_with_rest? ? children[0...-1] : children
          end

          def ends_with_rest?
            children.last.rest?
          end

          def rest_node
            children.last if ends_with_rest?
          end

          def arity
            return children.size unless ends_with_rest?

            ARITIES[children.size]
          end

          def in_sequence_head
            :raise
          end
        end

        setup_registry
      end
    end
  end
end
