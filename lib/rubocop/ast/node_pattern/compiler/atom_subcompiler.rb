# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      class Compiler
        # Generates code that evaluates to a value (Ruby object)
        # This value responds to `===`.
        class AtomSubcompiler < Subcompiler
          def self.compile(compiler, node)
            new(compiler, node).do_compile
          end

          private

          def visit_other_type
            compiler.with_temp_variables do |compare|
              code = compiler.compile_as_node_pattern( node, var: compare)
              "->(#{compare}) { #{code} }"
            end
          end

          def visit_unify
            compiler.bind(node.child) do
              raise Invalid, 'unified variables can not appear first as argument'
            end
          end

          def visit_symbol
            node.child.inspect
          end
          alias visit_number visit_symbol
          alias visit_string visit_symbol

          def visit_const
            node.child
          end

          def visit_named_parameter
            compiler.named_parameter(node.child)
          end

          def visit_positional_parameter
            compiler.positional_parameter(node.child)
          end
        end
      end
    end
  end
end
