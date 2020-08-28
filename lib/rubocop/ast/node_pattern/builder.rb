# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      # Responsible to build the AST nodes for `NoePattern`
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

        class Builder::WithLoc < Builder
          def emit_atom(type, token)
            value, loc = token
            begin_l = loc.resize(1)
            end_l = loc.end.adjust(begin_pos: -1)
            begin_l = nil if begin_l.source.match?(/\w/)
            end_l = nil if end_l.source.match?(/\w/)
            n(type, [value], source_map(token, begin_t: begin_l, end_t: end_l))
          end

          def emit_unary_op(type, operator_t = nil, *children)
            children[-1] = children[-1].first if children[-1].is_a?(Array) # token?
            map = source_map(children.first.loc.expression, operator_t: operator_t)
            n(type, children, map)
          end

          def emit_list(type, begin_t, children, end_t)
            expr = children.first.loc.expression.join(children.last.loc.expression)
            map = source_map(expr, begin_t: begin_t, end_t: end_t)
            n(type, children, map)
          end

          def emit_call(type, selector_t, args = nil)
            selector, = selector_t
            begin_t, arg_nodes, end_t = args

            map = source_map(selector_t, begin_t: begin_t, end_t: end_t, selector_t: selector_t)
            n(type, [selector, *arg_nodes], map)
          end

          private

          def n(type, children, source_map)
            super(type, children, { location: source_map })
          end

          def loc(token_or_range)
            return token_or_range[1] if token_or_range.is_a?(Array)

            token_or_range
          end

          def join_exprs(left_expr, right_expr)
            left_expr.loc.expression
                     .join(right_expr.loc.expression)
          end

          def source_map(token_or_range, begin_t: nil, end_t: nil, operator_t: nil, selector_t: nil)
            expression_l = loc(token_or_range)
            expression_l = expression_l.expression if expression_l.respond_to?(:expression)
            locs = [begin_t, end_t, operator_t, selector_t].map { |token| loc(token) }
            begin_l, end_l, operator_l, selector_l = locs

            expression_l = locs.compact.inject(expression_l, :join)

            ::Parser::Source::Map::Send.new(_dot_l = nil, selector_l, begin_l, end_l, expression_l)
                                       .with_operator(operator_l)
          end
        end
      end
    end
  end
end
