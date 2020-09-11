# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      # Responsible to build the AST nodes for `NodePattern`
      #
      # Doc on how this fits in the compiling process:
      #   /doc/modules/ROOT/pages/node_pattern.md
      class Builder
        def emit_capture(capture_token, node)
          return node if capture_token.nil?

          emit_unary_op(:capture, capture_token, node)
        end

        def emit_atom(type, value)
          n(type, [value])
        end

        def emit_unary_op(type, _operator = nil, *children)
          n(type, children)
        end

        def emit_list(type, _begin, children, _end)
          n(type, children)
        end

        def emit_call(type, selector, args = nil)
          _begin_t, arg_nodes, _end_t = args
          n(type, [selector, *arg_nodes])
        end

        private

        def n(type, *args)
          Node::MAP[type].new(type, *args)
        end
      end
    end
  end
end
