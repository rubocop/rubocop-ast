# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      # Finds the parts of a pattern that can never match, or that are there
      # twice:
      #
      # * node types that do not exist
      # * sequences that have more or fewer children than a node of that type
      # * children that are a node where a node of that type has a value like a
      #   symbol, and the other way around
      # * predicates that nothing responds to
      # * alternatives of a union that are repeated
      #
      #     Checker.new.check('(def _ _)').map(&:message)
      #     # => ['`def` nodes have 3 children, not 2.']
      #
      # A pattern that has none of these is not necessarily right.
      class Checker
        # What is wrong, and the node of the pattern that it is about. The
        # range is relative to the pattern.
        Problem = Struct.new(:node, :message) do
          def range
            node.source_range
          end
        end

        VALUES = [Symbol, String, Integer, Float, Rational, Complex, NilClass].freeze
        private_constant :VALUES

        # @return [Boolean] whether a pattern can have this node type in it
        def self.type?(type)
          AST::Node.method_defined?(:"#{type.to_s.tr('-', '_')}_type?")
        end

        # @param pattern [String]
        # @return [Array<Problem>]
        # @raise [NodePattern::Invalid] if the pattern can't be parsed
        def check(pattern)
          @problems = []
          visit(Parser::WithMeta.new.parse(pattern))
          @problems
        end

        private

        def visit(node)
          return unless node.is_a?(Node)

          case node.type
          when :node_type then check_type(node)
          when :sequence then check_sequence(node)
          when :predicate then check_predicate(node)
          when :union, :set then check_alternatives(node)
          end
          node.children.each { |child| visit(child) }
        end

        def problem(node, message)
          @problems << Problem.new(node, message)
        end

        def check_type(node)
          problem(node, "Unknown node type `#{node.child}`.") unless Checker.type?(node.child)
        end

        def check_sequence(node)
          SequenceCheck.new(node).problems.each { |term, message| problem(term, message) }
        end

        def check_predicate(node)
          name = node.method_name
          return if receivers.any? { |klass| klass.method_defined?(name) }

          problem(node, "Neither a node nor a child of one responds to `#{name}`.")
        end

        def receivers
          @receivers ||= VALUES + node_classes
        end

        def node_classes
          AST.constants.reject { |name| AST.autoload?(name) }
             .map { |name| AST.const_get(name) }
             .select { |const| const.is_a?(Class) && const <= AST::Node }
        end

        def check_alternatives(node)
          # What a union in the head of a sequence is rewritten to has no location.
          sources = node.children.grep(Node).filter_map { |child| child.loc&.expression&.source }
          sources.select { |source| sources.count(source) > 1 }.uniq.each do |source|
            problem(node, "`#{source}` is in the union more than once.")
          end
        end
      end
    end
  end
end

require_relative 'checker/sequence_check'
