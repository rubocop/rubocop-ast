# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      class Compiler
        # Compiles code that evalues to true or false
        # for a given value `var` (typically a RuboCop::AST::Node)
        # or it's `node.type` if `seq_head` is true
        class NodePatternSubcompiler < Subcompiler
          def self.compile(compiler, node, var: nil, access: var, seq_head: false)
            new(compiler, node, var, access, seq_head).do_compile
          end

          protected

          attr_reader :access, :seq_head

          private

          def initialize(compiler, node, var, access, seq_head)
            super(compiler, node)
            @var = var
            @access = access
            @seq_head = seq_head
          end

          def visit_other_type
            value = compiler.compile_as_atom( node)
            compile_value(value)
          end

          def visit_negation
            term = compile(node.child)
            "!(#{term})"
          end

          def visit_ascend
            compiler.with_temp_variables do |ascend|
              term = compiler.compile_as_node_pattern( node.child, var: ascend)
              "(#{ascend} = #{access_node}) && (#{ascend} = #{ascend}.parent) && #{term}"
            end
          end

          def visit_descend
            compiler.with_temp_variables { |descendant| <<~RUBY.chomp }
              ::RuboCop::AST::NodePattern.descend(#{access}).any? do |#{descendant}|
                #{compiler.compile_as_node_pattern( node.child, var: descendant)}
              end
            RUBY
          end

          def visit_wildcard
            'true'
          end

          def visit_unify
            name = compiler.bind(node.child) do |unify_name|
              # double assign to avoid "assigned but unused variable"
              return "(#{unify_name} = #{access_element}; #{unify_name} = #{unify_name}; true)"
            end

            compile_value(name)
          end

          def visit_capture
            "(#{compiler.next_capture} = #{access_element}; #{compile(node.child)})"
          end

          def compile_value(value)
            "#{value} === #{access_element}"
          end

          ### Lists

          def visit_union
            multiple_access(:union) do
              enum = compiler.union_bind(node.children)
              terms = compiler.enforce_same_captures(enum)
                             .map { |child| compile(child) }

              "(#{terms.join(' || ')})"
            end
          end

          def visit_intersection
            multiple_access(:intersection) do
              node.children.map { |child| compile(child) }
                  .join(' && ')
            end
          end

          def visit_predicate
            "#{access_element}.#{node.method_name}#{compile_args(node.arg_list)}"
          end

          def visit_function_call
            "#{node.method_name}#{compile_args(node.arg_list, first: access_element)}"
          end

          def visit_node_type
            "#{access_node}.#{node.child.to_s.tr('-', '_')}_type?"
          end

          def visit_sequence
            multiple_access(:sequence) do |var|
              term = compiler.compile_sequence( node, var: var)
              "#{compile_guard_clause} && #{term}"
            end
          end

          # Compiling helpers

          # @param [Array<Node>, nil]
          # @return [String, nil]
          def compile_args(arg_list, first: nil)
            args = arg_list&.map { |arg| compiler.compile_as_atom( arg) }
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

            compiler.with_temp_variables(kind) do |var|
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
