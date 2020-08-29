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

          def on_type_missing
            compiler.with_temp_variables do |compare|
              code = compiler.node_pattern.compile(compiler, node, var: compare)
              "->(#{compare}) { #{code} }"
            end
          end

          def on_unify
            compiler.bind(node.child) do
              raise Invalid, 'unified variables can not appear first as argument'
            end
          end

          def on_literal
            node.child.inspect
          end
          %i[on_symbol on_number on_string].each { |m| alias_method m, :on_literal }

          def on_const
            node.child
          end

          def on_named_parameter
            compiler.named_parameter(node.child)
          end

          def on_positional_parameter
            compiler.positional_parameter(node.child)
          end
        end
      end
    end
  end
end
