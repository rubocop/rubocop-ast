# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      class Compiler
        # Compiles code that evalues to true or false
        # for a given value `var` (typically a RuboCop::AST::Node)
        # or it's `node.type` if `seq_head` is true
        class NodePatternCompiler < Compiler
          def self.compile(context, node, var: nil, access: var, seq_head: false)
            new(context, node, var, access, seq_head).do_compile
          end

          protected

          attr_reader :access, :seq_head

          private

          def initialize(context, node, var, access, seq_head)
            super(context, node)
            @var = var
            @access = access
            @seq_head = seq_head
          end

          def on_type_missing
            value = context.atom.compile(context, node)
            compile_value(value)
          end

          def on_negation
            term = compile(node.child)
            "!(#{term})"
          end

          def on_ascend
            context.with_temp_variables do |ascend|
              term = context.node_pattern.compile(context, node.child, var: ascend)
              "(#{ascend} = #{access_node}) && (#{ascend} = #{ascend}.parent) && #{term}"
            end
          end

          def on_descend
            context.with_temp_variables { |descendant| <<~RUBY.chomp }
              ::RuboCop::AST::NodePattern.descend(#{access}).any? do |#{descendant}|
                #{context.node_pattern.compile(context, node.child, var: descendant)}
              end
            RUBY
          end

          def on_wildcard
            'true'
          end

          def on_unify
            name = context.bind(node.child) do |unify_name|
              # double assign to avoid "assigned but unused variable"
              return "(#{unify_name} = #{access_element}; #{unify_name} = #{unify_name}; true)"
            end

            compile_value(name)
          end

          def on_capture
            "(#{context.next_capture} = #{access_element}; #{compile(node.child)})"
          end

          def compile_value(value)
            "#{value} === #{access_element}"
          end

          ### Lists

          def on_union
            multiple_access(:union) do
              enum = context.union_bind(node.children)
              terms = context.enforce_same_captures(enum)
                             .map { |child| compile(child) }

              "(#{terms.join(' || ')})"
            end
          end

          def on_intersection
            multiple_access(:intersection) do
              node.children.map { |child| compile(child) }
                  .join(' && ')
            end
          end

          def on_predicate
            "#{access_element}.#{node.method_name}#{compile_args(node.arg_list)}"
          end

          def on_function_call
            "#{node.method_name}#{compile_args(node.arg_list, first: access_element)}"
          end

          def on_node_type
            "#{access_node}.#{node.child.to_s.tr('-', '_')}_type?"
          end

          def on_sequence
            multiple_access(:sequence) do |var|
              term = context.sequence.compile(context, node, var: var)
              "#{compile_guard_clause} && #{term}"
            end
          end

          # Compiling helpers

          # @param [Array<Node>, nil]
          # @return [String, nil]
          def compile_args(arg_list, first: nil)
            args = arg_list&.map { |arg| context.atom.compile(context, arg) }
            args = [first, *args] if first
            "(#{args.join(', ')})" if args
          end

          def access_element
            seq_head ? "#{access}.type" : access
          end

          def access_node
            return access if seq_head

            "#{compile_guard_clause} && #{access}"
          end

          def compile_guard_clause
            "#{access}.is_a?(::RuboCop::AST::Node)"
          end

          def multiple_access(kind)
            return yield @var if @var

            context.with_temp_variables(kind) do |var|
              memo = "#{var} = #{access}"
              @var = @access = var
              "(#{memo}; #{yield @var})"
            end
          end
        end
      end
    end
  end
end
