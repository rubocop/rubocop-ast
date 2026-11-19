# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      class Checker
        # Checks a sequence, like `(send _ :foo)`, against the layouts of the
        # node types that it is for.
        #
        # @api private
        class SequenceCheck
          LITERALS = { symbol: [Symbol], number: [Integer, Float, Rational, Complex], string: [String] }.freeze
          GROUPS = AST::Node::GROUP_FOR_TYPE.group_by(&:last)
                                            .transform_values { |pairs| pairs.map(&:first) }
                                            .freeze
          private_constant :LITERALS, :GROUPS

          # @return [Array<(NodePattern::Node, String)>] what is wrong, and with which node
          attr_reader :problems

          def initialize(node)
            @node = node
            @terms = node.children.drop(1)
            @problems = []
            alternatives = head_types(node.child)
            return unless alternatives

            fitting = check_arity(alternatives.map { |types| types.select { |type| NodeLayout.of(type) } })
            # The children of a type that has no layout can be anything.
            check_children(fitting) if alternatives.flatten.all? { |type| NodeLayout.of(type) }
          end

          private

          def problem(node, message)
            @problems << [node, message]
          end

          # @return [Array<Array<Symbol>>, nil] the node types that each
          #   alternative of the head stands for, if the head is nothing but
          #   node types
          def head_types(head)
            heads = head.type == :union ? head.children : [head]
            return unless heads.all? { |child| node_type?(child) }

            heads.map { |child| members(child.child) }
          end

          def node_type?(node)
            node.type == :node_type && Checker.type?(node.child)
          end

          # @return [Array<Symbol>] the types that a node type or a group stands for
          def members(type)
            type = type.to_s.tr('-', '_').to_sym
            GROUPS.fetch(type) { [type] }
          end

          # @return [Array<Symbol>] the types that can have as many children as the terms match
          def check_arity(alternatives)
            wanted = arity
            alternatives.flat_map do |types|
              fitting = types.select { |type| overlap?(NodeLayout.of(type).arity, wanted) }
              # A group is fine as long as one of its types fits.
              types.each { |type| arity_problem(type, wanted) } if fitting.empty?
              fitting
            end.uniq
          end

          # @return [Range] how many children the terms match
          def arity
            ranges = @terms.map(&:arity_range)
            ranges.sum(&:begin)..ranges.sum(&:end)
          end

          def overlap?(range, other)
            range.begin <= other.end && other.begin <= range.end
          end

          def arity_problem(type, wanted)
            has = count(NodeLayout.of(type).arity, 'children')
            problem(@node, "`#{type}` nodes have #{has}, not #{count(wanted)}.")
          end

          def count(range, noun = nil)
            number = if range.end == Float::INFINITY
                       "#{range.begin} or more"
                     elsif range.begin == range.end
                       range.begin.zero? && noun ? 'no' : range.begin.to_s
                     else
                       "#{range.begin} to #{range.end}"
                     end
            noun = 'child' if noun && range == (1..1)
            [number, noun].compact.join(' ')
          end

          def check_children(types)
            @terms.each_with_index do |term, index|
              # From here on, which child a term matches is not known.
              break unless term.arity == 1

              kinds = types.flat_map { |type| NodeLayout.of(type).kinds(index) }.uniq
              next if kinds.empty? || possible?(term, kinds)

              problem(term, "This never matches child #{index + 1} of `#{types.join('`, `')}` " \
                            "nodes, which is #{kinds.map { |kind| describe(kind) }.join(' or ')}.")
            end
          end

          # @return [Boolean] whether a term can match a child that is one of `kinds`
          def possible?(term, kinds)
            case term.type
            when :capture then possible?(term.child, kinds)
            when :union, :set then term.children.any? { |child| possible?(child, kinds) }
            when :intersection then term.children.all? { |child| possible?(child, kinds) }
            else kind?(term, kinds)
            end
          end

          def kind?(term, kinds)
            case term.type
            when :symbol, :number, :string then !(kinds & LITERALS.fetch(term.type)).empty?
            when :node_type then !Checker.type?(term.child) || kinds.include?(:node)
            when :sequence then kinds.include?(:node)
            when :predicate then term.children != [:nil?] || kinds.include?(NilClass)
            else true
            end
          end

          def describe(kind)
            return 'a node' if kind == :node
            return 'nil' if kind == NilClass

            "#{kind == Integer ? 'an' : 'a'} #{kind.name.downcase}"
          end
        end
      end
    end
  end
end
