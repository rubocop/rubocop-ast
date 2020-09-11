# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      class Compiler
        # Compiles terms within a sequence to code that evalues to true or false.
        # Compilation of the nodes that can match only a single term is deferred to
        # `NodePatternSubcompiler`; only nodes that can match multiple terms are
        # compiled here.
        # Assumes the given `var` is a `::RuboCop::AST::Node`
        #
        # Doc on how this fits in the compiling process:
        #   /doc/modules/ROOT/pages/node_pattern.md
        #
        # rubocop:disable Metrics/ClassLength
        class SequenceSubcompiler < Subcompiler
          DELTA = 1
          # Calls `compile_sequence`; the actual `compile` method
          # will be used for the different terms of the sequence.
          # The only case of re-entrant call to `compile` is `visit_capture`
          def initialize(compiler, sequence:, var:)
            @seq = sequence # The node to be compiled
            @seq_var = var  # Holds the name of the variable holding the AST::Node we are matching
            super(compiler)
          end

          def compile_sequence
            # rubocop:disable Layout/CommentIndentation
            compiler.with_temp_variables do |cur_child, cur_index, previous_index|
              @cur_child_var = cur_child        # To hold the current child node
              @cur_index_var = cur_index        # To hold the current child index (always >= 0)
              @prev_index_var = previous_index  # To hold the child index before we enter the
                                                # variadic nodes
              @cur_index = :seq_head            # Can be any of:
                                                # :seq_head : when the current child is actually the
                                                #             sequence head
                                                # :variadic_mode : child index held by @cur_index_var
                                                # >= 0 : when the current child index is known
                                                #        (from the begining)
                                                # < 0 :  when the index is known from the end,
                                                #        where -1 is *past the end*,
                                                #        -2 is the last child, etc...
                                                #        This shift of 1 from standard Ruby indices
                                                #        is stored in DELTA
              @in_sync = false                  # `true` iff `@cur_child_var` and `@cur_index_var`
                                                # correspond to `@cur_index`
                                                # Must be true if `@cur_index` is `:variadic_mode`
              compile_terms
            end
            # rubocop:enable Layout/CommentIndentation
          end

          private

          private :compile # Not meant to be called from outside

          # Single node patterns are all handled here
          def visit_other_type
            access = case @cur_index
                     when :seq_head
                       { var: @seq_var,
                         seq_head: true }
                     when :variadic_mode
                       { var: @cur_child_var }
                     else
                       idx = @cur_index + (@cur_index.negative? ? DELTA : 0)
                       { access: "#{@seq_var}.children[#{idx}]" }
                     end

            term = compiler.compile_as_node_pattern(node, **access)
            compile_and_advance(term)
          end

          def visit_repetition
            within_loop do
              child_captures = node.child.nb_captures
              child_code = compile(node.child)
              next compile_loop(child_code) if child_captures.zero?

              compile_captured_repetition(child_code, child_captures)
            end
          end

          def visit_any_order
            within_loop do
              compiler.with_temp_variables do |matched|
                case_terms = compile_any_order_branches(matched)
                else_code, init = compile_any_order_else
                term = "#{compile_case(case_terms, else_code)} && #{compile_loop_advance}"

                all_matched_check = "&&\n#{matched}.size == #{node.term_nodes.size}" if node.rest_node
                <<~RUBY
                  (#{init}#{matched} = {}; true) &&
                  #{compile_loop(term)} #{all_matched_check} \\
                RUBY
              end
            end
          end

          def compile_case(when_branches, else_code)
            <<~RUBY
              case
              #{when_branches.join('    ')}
              else #{else_code}
              end \\
            RUBY
          end

          def compile_any_order_branches(matched_var)
            node.term_nodes.map.with_index do |node, i|
              code = compiler.compile_as_node_pattern(node, var: @cur_child_var, seq_head: false)
              var = "#{matched_var}[#{i}]"
              "when !#{var} && #{code} then #{var} = true"
            end
          end

          # @return [Array<String>] Else code, and init code (if any)
          def compile_any_order_else
            rest = node.rest_node
            if !rest
              'false'
            elsif rest.capture?
              capture_rest = compiler.next_capture
              init = "#{capture_rest} = [];"
              ["#{capture_rest} << #{@cur_child_var}", init]
            else
              'true'
            end
          end

          def visit_capture
            return visit_other_type if node.child.arity == 1

            storage = compiler.next_capture
            term = compile(node.child)
            capture = "#{@seq_var}.children[#{compile_matched(:range)}]"
            "#{term} && (#{storage} = #{capture})"
          end

          def visit_rest
            empty_loop
          end

          # Compilation helpers

          def compile_and_advance(term)
            case @cur_index
            when :variadic_mode
              "#{term} && #{compile_loop_advance}"
            when :seq_head
              # @in_sync = false # already the case
              @cur_index = 0
              term
            else
              @in_sync = false
              @cur_index += 1
              term
            end
          end

          def compile_captured_repetition(child_code, child_captures)
            captured_range = "#{compiler.captures - child_captures}...#{compiler.captures}"
            captured = "captures[#{captured_range}]"
            compiler.with_temp_variables do |accumulate|
              code = "#{child_code} && #{accumulate}.push(#{captured})"
              <<~RUBY
                (#{accumulate} = Array.new) &&
                #{compile_loop(code)} &&
                (#{captured} = if #{accumulate}.empty?
                  (#{captured_range}).map{[]} # Transpose hack won't work for empty case
                else
                  #{accumulate}.transpose
                end) \\
              RUBY
            end
          end

          # Assumes `@cur_index` is already updated
          def compile_matched(kind)
            to = compile_cur_index
            from = if @prev_index == :variadic_mode
                     @prev_index_used = true
                     @prev_index_var
                   else
                     compile_index(@prev_index)
                   end
            case kind
            when :range
              "#{from}...#{to}"
            when :length
              "#{to} - #{from}"
            end
          end

          def handle_prev
            @prev_index = @cur_index
            @prev_index_used = false
            code = yield
            if @prev_index_used
              @prev_index_used = false
              code = "(#{@prev_index_var} = #{@cur_index_var}; true) && #{code}"
            end

            code
          end

          def compile_terms(children = @seq.children, last_arity = 0..0)
            arities = remaining_arities(children, last_arity)
            total_arity = arities.shift
            guard = compile_child_nb_guard(total_arity)
            return guard if children.empty?

            @remaining_arity = total_arity
            terms = children.map do |child|
              use_index_from_end
              @remaining_arity = arities.shift
              handle_prev { compile(child) }
            end
            [guard, terms].join(" &&\n")
          end

          # yield `sync_code` iff not already in sync
          def sync
            return if @in_sync

            code = compile_loop_advance("= #{compile_cur_index}")
            @in_sync = true
            yield code
          end

          # @return [Array<Range>] total arities (as Ranges) of remaining children nodes
          # E.g. For sequence `(_  _? <_ _>)`, arities are: 1, 0..1, 2
          # and remaining arities are: 3..4, 2..3, 2..2, 0..0
          def remaining_arities(children, last_arity)
            last = last_arity
            arities = children
                      .reverse
                      .map(&:arity_range)
                      .map { |r| last = last.begin + r.begin..last.max + r.max }
                      .reverse!
            arities.push last_arity
          end

          # @return [String] code that evaluates to `false` if the matched arity is too small
          def compile_min_check
            return 'false' unless node.variadic?

            unless @remaining_arity.end.infinite?
              not_too_much_remaining = "#{compile_remaining} <= #{@remaining_arity.max}"
            end
            min_to_match = node.arity_range.begin
            if min_to_match.positive?
              enough_matched = "#{compile_matched(:length)} >= #{min_to_match}"
            end
            return 'true' unless not_too_much_remaining || enough_matched

            [not_too_much_remaining, enough_matched].compact.join(' && ')
          end

          def compile_remaining
            "#{@seq_var}.children.size - #{@cur_index_var}"
          end

          def compile_max_matched
            return node.arity unless node.variadic?

            min_remaining_children = "#{compile_remaining} - #{@remaining_arity.begin}"
            return min_remaining_children if node.arity.end.infinite?

            "[#{min_remaining_children}, #{node.arity.max}].min"
          end

          def empty_loop
            @cur_index = -@remaining_arity.begin - DELTA
            @in_sync = false
            'true'
          end

          def compile_cur_index
            return @cur_index_var if @in_sync

            compile_index
          end

          def compile_index(cur = @cur_index)
            return cur if cur >= 0

            "#{@seq_var}.children.size - #{-(cur + DELTA)}"
          end

          # Note: assumes `@cur_index != :seq_head`. Node types using `within_loop` must
          # have `def in_sequence_head; :raise; end`
          def within_loop
            sync do |sync_code|
              @cur_index = :variadic_mode
              "#{sync_code} && #{yield}"
            end || yield
          end

          # returns truthy iff `@cur_index` switched to relative from end mode (i.e. < 0)
          def use_index_from_end
            return if @cur_index == :seq_head || @remaining_arity.begin != @remaining_arity.max

            @cur_index = -@remaining_arity.begin - DELTA
          end

          def compile_loop_advance(to = '+=1')
            # The `#{@cur_child_var} ||` is just to avoid unused variable warning
            "(#{@cur_child_var} = #{@seq_var}.children[#{@cur_index_var} #{to}]; " \
            "#{@cur_child_var} || true)"
          end

          def compile_loop(term)
            <<~RUBY
              (#{compile_max_matched}).times do
                break #{compile_min_check} unless #{term}
              end \\
            RUBY
          end

          def compile_child_nb_guard(arity_range)
            # The -1 are because of seq_head
            case arity_range.max
            when Float::INFINITY
              "#{@seq_var}.children.size >= #{arity_range.begin - 1}"
            when arity_range.begin
              "#{@seq_var}.children.size == #{arity_range.begin - 1}"
            else
              "(#{arity_range.begin - 1}..#{arity_range.max - 1}).cover?(#{@seq_var}.children.size)"
            end
          end
        end
        # rubocop:enable Metrics/ClassLength
      end
    end
  end
end
