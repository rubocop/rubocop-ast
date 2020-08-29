# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      class Compiler
        # Generates code that evaluates to a value (Ruby object)
        # This value responds to `===`.
        class AtomSubcompiler < Compiler
          def self.compile(context, node)
            new(context, node).do_compile
          end

          private

          def on_type_missing
            context.with_temp_variables do |compare|
              code = context.node_pattern.compile(context, node, var: compare)
              "->(#{compare}) { #{code} }"
            end
          end

          def on_unify
            context.bind(node.child) do
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
            context.named_parameter(node.child)
          end

          def on_positional_parameter
            context.positional_parameter(node.child)
          end
        end
      end
    end
  end
end
