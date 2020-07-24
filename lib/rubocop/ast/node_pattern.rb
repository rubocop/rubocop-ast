# frozen_string_literal: true

require 'delegate'
require 'erb'

# rubocop:disable Metrics/ClassLength, Metrics/CyclomaticComplexity
module RuboCop
  module AST
    # This class performs a pattern-matching operation on an AST node.
    #
    # Initialize a new `NodePattern` with `NodePattern.new(pattern_string)`, then
    # pass an AST node to `NodePattern#match`. Alternatively, use one of the class
    # macros in `NodePattern::Macros` to define your own pattern-matching method.
    #
    # If the match fails, `nil` will be returned. If the match succeeds, the
    # return value depends on whether a block was provided to `#match`, and
    # whether the pattern contained any "captures" (values which are extracted
    # from a matching AST.)
    #
    # - With block: #match yields the captures (if any) and passes the return
    #               value of the block through.
    # - With no block, but one capture: the capture is returned.
    # - With no block, but multiple captures: captures are returned as an array.
    # - With no block and no captures: #match returns `true`.
    #
    # ## Pattern string format examples
    #
    #     ':sym'              # matches a literal symbol
    #     '1'                 # matches a literal integer
    #     'nil'               # matches a literal nil
    #     'send'              # matches (send ...)
    #     '(send)'            # matches (send)
    #     '(send ...)'        # matches (send ...)
    #     '(op-asgn)'         # node types with hyphenated names also work
    #     '{send class}'      # matches (send ...) or (class ...)
    #     '({send class})'    # matches (send) or (class)
    #     '(send const)'      # matches (send (const ...))
    #     '(send _ :new)'     # matches (send <anything> :new)
    #     '(send $_ :new)'    # as above, but whatever matches the $_ is captured
    #     '(send $_ $_)'      # you can use as many captures as you want
    #     '(send !const ...)' # ! negates the next part of the pattern
    #     '$(send const ...)' # arbitrary matching can be performed on a capture
    #     '(send _recv _msg)' # wildcards can be named (for readability)
    #     '(send ... :new)'   # you can match against the last children
    #     '(array <str sym>)' # you can match children in any order. This
    #                         # would match `['x', :y]` as well as `[:y, 'x']
    #     '(_ <str sym ...>)' # will match if arguments have at least a `str` and
    #                         # a `sym` node, but can have more.
    #     '(array <$str $_>)' # captures are in the order of the pattern,
    #                         # irrespective of the actual order of the children
    #     '(array int*)'      # will match an array of 0 or more integers
    #     '(array int ?)'     # will match 0 or 1 integer.
    #                         # Note: Space needed to distinguish from int?
    #     '(array int+)'      # will match an array of 1 or more integers
    #     '(array (int $_)+)' # as above and will capture the numbers in an array
    #     '(send $...)'       # capture all the children as an array
    #     '(send $... int)'   # capture all children but the last as an array
    #     '(send _x :+ _x)'   # unification is performed on named wildcards
    #                         # (like Prolog variables...)
    #                         # (#== is used to see if values unify)
    #     '(int odd?)'        # words which end with a ? are predicate methods,
    #                         # are are called on the target to see if it matches
    #                         # any Ruby method which the matched object supports
    #                         # can be used
    #                         # if a truthy value is returned, the match succeeds
    #     '(int [!1 !2])'     # [] contains multiple patterns, ALL of which must
    #                         # match in that position
    #                         # in other words, while {} is pattern union (logical
    #                         # OR), [] is intersection (logical AND)
    #     '(send %1 _)'       # % stands for a parameter which must be supplied to
    #                         # #match at matching time
    #                         # it will be compared to the corresponding value in
    #                         # the AST using #=== so you can pass Procs, Regexp,
    #                         # etc. in addition to Nodes or literals.
    #                         # `Array#===` will never match a node element, but
    #                         # `Set#===` is an alias to `Set#include?` (Ruby 2.5+
    #                         # only), and so can be very useful to match within
    #                         # many possible literals / Nodes.
    #                         # a bare '%' is the same as '%1'
    #                         # the number of extra parameters passed to #match
    #                         # must equal the highest % value in the pattern
    #                         # for consistency, %0 is the 'root node' which is
    #                         # passed as the 1st argument to #match, where the
    #                         # matching process starts
    #     '(send _ %named)'   # arguments can also be passed as named
    #                         # parameters (see `%1`)
    #                         # Note that the macros `def_node_matcher` and
    #                         # `def_node_search` accept default values for these.
    #     '(send _ %CONST)'   # the named constant will act like `%1` and `%named`.
    #     '^^send'            # each ^ ascends one level in the AST
    #                         # so this matches against the grandparent node
    #     '`send'             # descends any number of level in the AST
    #                         # so this matches against any descendant node
    #     '#method'           # we call this a 'funcall'; it calls a method in the
    #                         # context where a pattern-matching method is defined
    #                         # if that returns a truthy value, the match succeeds
    #     'equal?(%1)'        # predicates can be given 1 or more extra args
    #     '#method(%0, 1)'    # funcalls can also be given 1 or more extra args
    #                         # These arguments can be patterns themselves, in
    #                         # which case a matcher responding to === will be
    #                         # passed.
    #     '# comment'         # comments are accepted at the end of lines
    #
    # You can nest arbitrarily deep:
    #
    #     # matches node parsed from 'Const = Class.new' or 'Const = Module.new':
    #     '(casgn nil? :Const (send (const nil? {:Class :Module}) :new))'
    #     # matches a node parsed from an 'if', with a '==' comparison,
    #     # and no 'else' branch:
    #     '(if (send _ :== _) _ nil?)'
    #
    # Note that patterns like 'send' are implemented by calling `#send_type?` on
    # the node being matched, 'const' by `#const_type?`, 'int' by `#int_type?`,
    # and so on. Therefore, if you add methods which are named like
    # `#prefix_type?` to the AST node class, then 'prefix' will become usable as
    # a pattern.
    class NodePattern
      # @private
      Invalid = Class.new(StandardError)

      # @private
      # Builds Ruby code which implements a pattern
      class Compiler
        SYMBOL       = %r{:(?:[\w+@*/?!<>=~|%^-]+|\[\]=?)}.freeze
        IDENTIFIER   = /[a-zA-Z_][a-zA-Z0-9_-]*/.freeze
        COMMENT      = /#\s.*$/.freeze

        META         = Regexp.union(
          %w"( ) { } [ ] $< < > $... $ ! ^ ` ... + * ?"
        ).freeze
        NUMBER       = /-?\d+(?:\.\d+)?/.freeze
        STRING       = /".+?"/.freeze
        METHOD_NAME  = /\#?#{IDENTIFIER}[!?]?\(?/.freeze
        PARAM_CONST  = /%[A-Z:][a-zA-Z_:]+/.freeze
        KEYWORD_NAME = /%[a-z_]+/.freeze
        PARAM_NUMBER = /%\d*/.freeze

        SEPARATORS = /\s+/.freeze
        ONLY_SEPARATOR = /\A#{SEPARATORS}\Z/.freeze

        TOKENS = Regexp.union(META, PARAM_CONST, KEYWORD_NAME, PARAM_NUMBER, NUMBER,
                              METHOD_NAME, SYMBOL, STRING)

        TOKEN = /\G(?:#{SEPARATORS}|#{TOKENS}|.)/.freeze

        NODE      = /\A#{IDENTIFIER}\Z/.freeze
        PREDICATE = /\A#{IDENTIFIER}\?\(?\Z/.freeze
        WILDCARD  = /\A_(?:#{IDENTIFIER})?\Z/.freeze

        FUNCALL   = /\A\##{METHOD_NAME}/.freeze
        LITERAL   = /\A(?:#{SYMBOL}|#{NUMBER}|#{STRING})\Z/.freeze
        PARAM     = /\A#{PARAM_NUMBER}\Z/.freeze
        CONST     = /\A#{PARAM_CONST}\Z/.freeze
        KEYWORD   = /\A#{KEYWORD_NAME}\Z/.freeze
        CLOSING   = /\A(?:\)|\}|\])\Z/.freeze

        REST      = '...'
        CAPTURED_REST = '$...'

        attr_reader :match_code, :tokens, :captures

        SEQ_HEAD_INDEX = -1

        # Placeholders while compiling, see with_..._context methods
        CUR_PLACEHOLDER = '@@@cur'
        CUR_NODE = "#{CUR_PLACEHOLDER} node@@@"
        CUR_ELEMENT = "#{CUR_PLACEHOLDER} element@@@"
        SEQ_HEAD_GUARD = '@@@seq guard head@@@'
        MULTIPLE_CUR_PLACEHOLDER = /#{CUR_PLACEHOLDER}.*#{CUR_PLACEHOLDER}/.freeze

        line = __LINE__
        ANY_ORDER_TEMPLATE = ERB.new <<~RUBY.gsub("-%>\n", '%>')
          <% if capture_rest %>(<%= capture_rest %> = []) && <% end -%>
          <% if capture_all %>(<%= capture_all %> = <% end -%>
          <%= CUR_NODE %>.children[<%= range %>]<% if capture_all %>)<% end -%>
          .each_with_object({}) { |<%= child %>, <%= matched %>|
            case
            <% patterns.each_with_index do |pattern, i| -%>
            when !<%= matched %>[<%= i %>] && <%=
              with_context(pattern, child, use_temp_node: false)
            %> then <%= matched %>[<%= i %>] = true
            <% end -%>
            <% if !rest %>  else break({})
            <% elsif capture_rest %>  else <%= capture_rest %> << <%= child %>
            <% end -%>
            end
          }.size == <%= patterns.size -%>
        RUBY
        ANY_ORDER_TEMPLATE.location = [__FILE__, line + 1]

        line = __LINE__
        REPEATED_TEMPLATE = ERB.new <<~RUBY.gsub("-%>\n", '%>')
          <% if captured %>(<%= accumulate %> = Array.new) && <% end %>
          <%= CUR_NODE %>.children[<%= range %>].all? do |<%= child %>|
            <%= with_context(expr, child, use_temp_node: false) %><% if captured %>&&
            <%= accumulate %>.push(<%= captured %>)<% end %>
          end <% if captured %>&&
          (<%= captured %> = if <%= accumulate %>.empty?
            <%= captured %>.map{[]} # Transpose hack won't work for empty case
          else
            <%= accumulate %>.transpose
          end) <% end -%>
        RUBY
        REPEATED_TEMPLATE.location = [__FILE__, line + 1]

        def initialize(str, root = 'node0', node_var = root)
          @string   = str
          # For def_node_pattern, root == node_var
          # For def_node_search, root is the root node to search on,
          # and node_var is the current descendant being searched.
          @root     = root
          @node_var = node_var

          @temps    = 0  # avoid name clashes between temp variables
          @captures = 0  # number of captures seen
          @unify    = {} # named wildcard -> temp variable
          @params   = 0  # highest % (param) number seen
          @keywords = Set[] # keyword parameters seen
          run
        end

        def run
          @tokens = Compiler.tokens(@string)

          @match_code = with_context(compile_expr, @node_var, use_temp_node: false)
          @match_code.prepend("(captures = Array.new(#{@captures})) && ") \
            if @captures.positive?

          fail_due_to('unbalanced pattern') unless tokens.empty?
        end

        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        def compile_expr(token = tokens.shift)
          # read a single pattern-matching expression from the token stream,
          # return Ruby code which performs the corresponding matching operation
          #
          # the 'pattern-matching' expression may be a composite which
          # contains an arbitrary number of sub-expressions, but that composite
          # must all have precedence higher or equal to that of `&&`
          #
          # Expressions may use placeholders like:
          #   CUR_NODE: Ruby code that evaluates to an AST node
          #   CUR_ELEMENT: Either the node or the type if in first element of
          #   a sequence (aka seq_head, e.g. "(seq_head first_node_arg ...")
          if (atom = compile_atom(token))
            return atom_to_expr(atom)
          end

          case token
          when '('       then compile_seq
          when '{'       then compile_union
          when '['       then compile_intersect
          when '!'       then compile_negation
          when '$'       then compile_capture
          when '^'       then compile_ascend
          when '`'       then compile_descend
          when WILDCARD  then compile_new_wildcard(token[1..-1])
          when FUNCALL   then compile_funcall(token)
          when PREDICATE then compile_predicate(token)
          when NODE      then compile_nodetype(token)
          else                fail_due_to("invalid token #{token.inspect}")
          end
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

        def tokens_until(stop, what)
          return to_enum __method__, stop, what unless block_given?

          fail_due_to("empty #{what}") if tokens.first == stop
          yield until tokens.first == stop
          tokens.shift
        end

        def compile_seq
          terms = tokens_until(')', 'sequence').map { variadic_seq_term }
          Sequence.new(self, *terms).compile
        end

        def compile_guard_clause
          "#{CUR_NODE}.is_a?(RuboCop::AST::Node)"
        end

        def variadic_seq_term
          token = tokens.shift
          case token
          when CAPTURED_REST then compile_captured_ellipsis
          when REST          then compile_ellipsis
          when '$<'          then compile_any_order(next_capture)
          when '<'           then compile_any_order
          else                    compile_repeated_expr(token)
          end
        end

        def compile_repeated_expr(token)
          before = @captures
          expr = compile_expr(token)
          min, max = parse_repetition_token
          return [1, expr] if min.nil?

          if @captures != before
            captured = "captures[#{before}...#{@captures}]"
            accumulate = next_temp_variable(:accumulate)
          end
          arity = min..max || Float::INFINITY

          [arity, repeated_generator(expr, captured, accumulate)]
        end

        def repeated_generator(expr, captured, accumulate)
          with_temp_variables do |child|
            lambda do |range|
              fail_due_to 'repeated pattern at beginning of sequence' if range.begin == SEQ_HEAD_INDEX
              REPEATED_TEMPLATE.result(binding)
            end
          end
        end

        def parse_repetition_token
          case tokens.first
          when '*' then min = 0
          when '+' then min = 1
          when '?' then min = 0
                        max = 1
          else          return
          end
          tokens.shift
          [min, max]
        end

        # @private
        # Builds Ruby code for a sequence
        # (head *first_terms variadic_term *last_terms)
        class Sequence
          extend Forwardable
          def_delegators :@compiler, :compile_guard_clause, :with_seq_head_context,
                         :with_child_context, :fail_due_to

          def initialize(compiler, *arity_term_list)
            @arities, @terms = arity_term_list.transpose

            @compiler = compiler
            @variadic_index = @arities.find_index { |a| a.is_a?(Range) }
            fail_due_to 'multiple variable patterns in same sequence' \
              if @variadic_index && !@arities.one? { |a| a.is_a?(Range) }
          end

          def compile
            [
              compile_guard_clause,
              compile_child_nb_guard,
              compile_seq_head,
              *compile_first_terms,
              compile_variadic_term,
              *compile_last_terms
            ].compact.join(" &&\n") << SEQ_HEAD_GUARD
          end

          private

          def first_terms_arity
            first_terms_range { |r| @arities[r].inject(0, :+) } || 0
          end

          def last_terms_arity
            last_terms_range { |r| @arities[r].inject(0, :+) } || 0
          end

          def variadic_term_min_arity
            @variadic_index ? @arities[@variadic_index].begin : 0
          end

          def first_terms_range
            yield 1..(@variadic_index || @terms.size) - 1 if seq_head?
          end

          def last_terms_range
            yield @variadic_index + 1...@terms.size if @variadic_index
          end

          def seq_head?
            @variadic_index != 0
          end

          def compile_child_nb_guard
            fixed = first_terms_arity + last_terms_arity
            min = fixed + variadic_term_min_arity
            op = if @variadic_index
                   max_variadic = @arities[@variadic_index].end
                   if max_variadic != Float::INFINITY
                     range = min..fixed + max_variadic
                     return "(#{range}).cover?(#{CUR_NODE}.children.size)"
                   end
                   '>='
                 else
                   '=='
                 end
            "#{CUR_NODE}.children.size #{op} #{min}"
          end

          def term(index, range)
            t = @terms[index]
            if t.respond_to? :call
              t.call(range)
            else
              with_child_context(t, range.begin)
            end
          end

          def compile_seq_head
            return unless seq_head?

            fail_due_to 'sequences cannot start with <' \
              if @terms[0].respond_to? :call

            with_seq_head_context(@terms[0])
          end

          def compile_first_terms
            first_terms_range { |range| compile_terms(range, 0) }
          end

          def compile_last_terms
            last_terms_range { |r| compile_terms(r, -last_terms_arity) }
          end

          def compile_terms(index_range, start)
            index_range.map do |i|
              current = start
              start += @arities.fetch(i)
              term(i, current..start - 1)
            end
          end

          def compile_variadic_term
            variadic_arity { |arity| term(@variadic_index, arity) }
          end

          def variadic_arity
            return unless @variadic_index

            first = @variadic_index.positive? ? first_terms_arity : SEQ_HEAD_INDEX
            yield first..-last_terms_arity - 1
          end
        end
        private_constant :Sequence

        def compile_captured_ellipsis
          capture = next_capture
          block = lambda { |range|
            # Consider ($...) like (_ $...):
            range = 0..range.end if range.begin == SEQ_HEAD_INDEX
            "(#{capture} = #{CUR_NODE}.children[#{range}])"
          }
          [0..Float::INFINITY, block]
        end

        def compile_ellipsis
          [0..Float::INFINITY, 'true']
        end

        # rubocop:disable Metrics/MethodLength
        def compile_any_order(capture_all = nil)
          rest = capture_rest = nil
          patterns = []
          with_temp_variables do |child, matched|
            tokens_until('>', 'any child') do
              fail_due_to 'ellipsis must be at the end of <>' if rest
              token = tokens.shift
              case token
              when CAPTURED_REST then rest = capture_rest = next_capture
              when REST          then rest = true
              else patterns << compile_expr(token)
              end
            end
            [rest ? patterns.size..Float::INFINITY : patterns.size,
             ->(range) { ANY_ORDER_TEMPLATE.result(binding) }]
          end
        end
        # rubocop:enable Metrics/MethodLength

        def insure_same_captures(enum, what)
          return to_enum __method__, enum, what unless block_given?

          captures_before = captures_after = nil
          enum.each do
            captures_before ||= @captures
            @captures = captures_before
            yield
            captures_after ||= @captures
            fail_due_to("each #{what} must have same # of captures") if captures_after != @captures
          end
        end

        def access_unify(name)
          var = @unify[name]

          if var == :forbidden_unification
            fail_due_to "Wildcard #{name} was first seen in a subset of a" \
                        " union and can't be used outside that union"
          end
          var
        end

        def forbid_unification(*names)
          names.each do |name|
            @unify[name] = :forbidden_unification
          end
        end

        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        def unify_in_union(enum)
          # We need to reset @unify before each branch is processed.
          # Moreover we need to keep track of newly encountered wildcards.
          # Var `new_unify_intersection` will hold those that are encountered
          # in all branches; these are not a problem.
          # Var `partial_unify` will hold those encountered in only a subset
          # of the branches; these can't be used outside of the union.

          return to_enum __method__, enum unless block_given?

          new_unify_intersection = nil
          partial_unify = []
          unify_before = @unify.dup

          result = enum.each do |e|
            @unify = unify_before.dup if new_unify_intersection
            yield e
            new_unify = @unify.keys - unify_before.keys
            if new_unify_intersection.nil?
              # First iteration
              new_unify_intersection = new_unify
            else
              union = new_unify_intersection | new_unify
              new_unify_intersection &= new_unify
              partial_unify |= union - new_unify_intersection
            end
          end

          # At this point, all members of `new_unify_intersection` can be used
          # for unification outside of the union, but partial_unify may not

          forbid_unification(*partial_unify)

          result
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

        def compile_union
          # we need to ensure that each branch of the {} contains the same
          # number of captures (since only one branch of the {} can actually
          # match, the same variables are used to hold the captures for each
          # branch)
          enum = tokens_until('}', 'union')
          enum = unify_in_union(enum)
          terms = insure_same_captures(enum, 'branch of {}')
                  .map { compile_expr }

          "(#{terms.join(' || ')})"
        end

        def compile_intersect
          tokens_until(']', 'intersection')
            .map { compile_expr }
            .join(' && ')
        end

        def compile_capture
          "(#{next_capture} = #{CUR_ELEMENT}; #{compile_expr})"
        end

        def compile_negation
          "!(#{compile_expr})"
        end

        def compile_ascend
          with_context("#{CUR_NODE} && #{compile_expr}", "#{CUR_NODE}.parent")
        end

        def compile_descend
          with_temp_variables do |descendant|
            pattern = with_context(compile_expr, descendant,
                                   use_temp_node: false)
            [
              "RuboCop::AST::NodePattern.descend(#{CUR_ELEMENT}).",
              "any? do |#{descendant}|",
              "  #{pattern}",
              'end'
            ].join("\n")
          end
        end

        # Known wildcards are considered atoms, see `compile_atom`
        def compile_new_wildcard(name)
          return 'true' if name.empty?

          n = @unify[name] = "unify_#{name.gsub('-', '__')}"
          # double assign to avoid "assigned but unused variable"
          "(#{n} = #{CUR_ELEMENT}; #{n} = #{n}; true)"
        end

        def compile_predicate(predicate)
          if predicate.end_with?('(') # is there an arglist?
            args = compile_args
            predicate = predicate[0..-2] # drop the trailing (
            "#{CUR_ELEMENT}.#{predicate}(#{args.join(',')})"
          else
            "#{CUR_ELEMENT}.#{predicate}"
          end
        end

        def compile_funcall(method)
          # call a method in the context which this pattern-matching
          # code is used in. pass target value as an argument
          method = method[1..-1] # drop the leading #
          if method.end_with?('(') # is there an arglist?
            args = compile_args
            method = method[0..-2] # drop the trailing (
            "#{method}(#{CUR_ELEMENT},#{args.join(',')})"
          else
            "#{method}(#{CUR_ELEMENT})"
          end
        end

        def compile_nodetype(type)
          "#{compile_guard_clause} && #{CUR_NODE}.#{type.tr('-', '_')}_type?"
        end

        def compile_args
          tokens_until(')', 'call arguments').map do
            arg = compile_arg
            tokens.shift if tokens.first == ','
            arg
          end
        end

        def atom_to_expr(atom)
          "#{atom} === #{CUR_ELEMENT}"
        end

        def expr_to_atom(expr)
          with_temp_variables do |compare|
            in_context = with_context(expr, compare, use_temp_node: false)
            "::RuboCop::AST::NodePattern::Matcher.new{|#{compare}| #{in_context}}"
          end
        end

        # @return compiled atom (e.g. ":literal" or "SOME_CONST")
        #         or nil if not a simple atom (unknown wildcard, other tokens)
        def compile_atom(token)
          case token
          when WILDCARD  then access_unify(token[1..-1]) # could be nil
          when LITERAL   then token
          when KEYWORD   then get_keyword(token[1..-1])
          when CONST     then get_const(token[1..-1])
          when PARAM     then get_param(token[1..-1])
          when CLOSING   then fail_due_to("#{token} in invalid position")
          when nil       then fail_due_to('pattern ended prematurely')
          end
        end

        def compile_arg
          token = tokens.shift
          compile_atom(token) || expr_to_atom(compile_expr(token))
        end

        def next_capture
          index = @captures
          @captures += 1
          "captures[#{index}]"
        end

        def get_param(number)
          number = number.empty? ? 1 : Integer(number)
          @params = number if number > @params
          number.zero? ? @root : "param#{number}"
        end

        def get_keyword(name)
          @keywords << name
          name
        end

        def get_const(const)
          const # Output the constant exactly as given
        end

        def emit_yield_capture(when_no_capture = '')
          yield_val = if @captures.zero?
                        when_no_capture
                      elsif @captures == 1
                        'captures[0]' # Circumvent https://github.com/jruby/jruby/issues/5710
                      else
                        '*captures'
                      end
          "yield(#{yield_val})"
        end

        def emit_retval
          if @captures.zero?
            'true'
          elsif @captures == 1
            'captures[0]'
          else
            'captures'
          end
        end

        def emit_param_list
          (1..@params).map { |n| "param#{n}" }.join(',')
        end

        def emit_keyword_list(forwarding: false)
          pattern = "%<keyword>s: #{'%<keyword>s' if forwarding}"
          @keywords.map { |k| format(pattern, keyword: k) }.join(',')
        end

        def emit_params(*first, forwarding: false)
          params = emit_param_list
          keywords = emit_keyword_list(forwarding: forwarding)
          [*first, params, keywords].reject(&:empty?).join(',')
        end

        def emit_method_code
          <<~RUBY
            return unless #{@match_code}
            block_given? ? #{emit_yield_capture} : (return #{emit_retval})
          RUBY
        end

        def fail_due_to(message)
          raise Invalid, "Couldn't compile due to #{message}. Pattern: #{@string}"
        end

        def with_temp_node(cur_node)
          with_temp_variables do |node|
            yield "(#{node} = #{cur_node})", node
          end
            .gsub("\n", "\n  ") # Nicer indent for debugging
        end

        def with_temp_variables(&block)
          names = block.parameters.map { |_, name| next_temp_variable(name) }
          yield(*names)
        end

        def next_temp_variable(name)
          "#{name}#{next_temp_value}"
        end

        def next_temp_value
          @temps += 1
        end

        def auto_use_temp_node?(code)
          code.match?(MULTIPLE_CUR_PLACEHOLDER)
        end

        # with_<...>_context methods are used whenever the context,
        # i.e the current node or the current element can be determined.

        def with_child_context(code, child_index)
          with_context(code, "#{CUR_NODE}.children[#{child_index}]")
        end

        def with_context(code, cur_node,
                         use_temp_node: auto_use_temp_node?(code))
          if use_temp_node
            with_temp_node(cur_node) do |init, temp_var|
              substitute_cur_node(code, temp_var, first_cur_node: init)
            end
          else
            substitute_cur_node(code, cur_node)
          end
        end

        def with_seq_head_context(code)
          fail_due_to('parentheses at sequence head') if code.include?(SEQ_HEAD_GUARD)

          code.gsub CUR_ELEMENT, "#{CUR_NODE}.type"
        end

        def substitute_cur_node(code, cur_node, first_cur_node: cur_node)
          iter = 0
          code
            .gsub(CUR_ELEMENT, CUR_NODE)
            .gsub(CUR_NODE) do
              iter += 1
              iter == 1 ? first_cur_node : cur_node
            end
            .gsub(SEQ_HEAD_GUARD, '')
        end

        def self.tokens(pattern)
          pattern.gsub(COMMENT, '').scan(TOKEN).grep_v(ONLY_SEPARATOR)
        end

        # This method minimizes the closure for our method
        def wrapping_block(method_name, **defaults)
          proc do |*args, **values|
            send method_name, *args, **defaults, **values
          end
        end

        def def_helper(base, method_name, **defaults)
          location = caller_locations(3, 1).first
          unless defaults.empty?
            call = :"without_defaults_#{method_name}"
            base.send :define_method, method_name, &wrapping_block(call, **defaults)
            method_name = call
          end
          src = yield method_name
          base.class_eval(src, location.path, location.lineno)
        end

        def def_node_matcher(base, method_name, **defaults)
          def_helper(base, method_name, **defaults) do |name|
            <<~RUBY
              def #{name}(#{emit_params('node = self')})
                #{emit_method_code}
              end
            RUBY
          end
        end

        def def_node_search(base, method_name, **defaults)
          def_helper(base, method_name, **defaults) do |name|
            emit_node_search(name)
          end
        end

        def emit_node_search(method_name)
          if method_name.to_s.end_with?('?')
            on_match = 'return true'
          else
            args = emit_params(":#{method_name}", @root, forwarding: true)
            prelude = "return enum_for(#{args}) unless block_given?\n"
            on_match = emit_yield_capture(@node_var)
          end
          emit_node_search_body(method_name, prelude: prelude, on_match: on_match)
        end

        def emit_node_search_body(method_name, prelude:, on_match:)
          <<~RUBY
            def #{method_name}(#{emit_params(@root)})
              #{prelude}
              #{@root}.each_node do |#{@node_var}|
                if #{match_code}
                  #{on_match}
                end
              end
              nil
            end
          RUBY
        end
      end
      private_constant :Compiler

      # Helpers for defining methods based on a pattern string
      module Macros
        # Define a method which applies a pattern to an AST node
        #
        # The new method will return nil if the node does not match
        # If the node matches, and a block is provided, the new method will
        # yield to the block (passing any captures as block arguments).
        # If the node matches, and no block is provided, the new method will
        # return the captures, or `true` if there were none.
        def def_node_matcher(method_name, pattern_str, **keyword_defaults)
          Compiler.new(pattern_str, 'node')
                  .def_node_matcher(self, method_name, **keyword_defaults)
        end

        # Define a method which recurses over the descendants of an AST node,
        # checking whether any of them match the provided pattern
        #
        # If the method name ends with '?', the new method will return `true`
        # as soon as it finds a descendant which matches. Otherwise, it will
        # yield all descendants which match.
        def def_node_search(method_name, pattern_str, **keyword_defaults)
          Compiler.new(pattern_str, 'node0', 'node')
                  .def_node_search(self, method_name, **keyword_defaults)
        end
      end

      attr_reader :pattern

      def initialize(str)
        @pattern = str
        compiler = Compiler.new(str, 'node0')
        src = "def match(#{compiler.emit_params('node0')});" \
              "#{compiler.emit_method_code}end"
        instance_eval(src, __FILE__, __LINE__ + 1)
      end

      def match(*args, **rest)
        # If we're here, it's because the singleton method has not been defined,
        # either because we've been dup'ed or serialized through YAML
        initialize(pattern)
        if rest.empty?
          match(*args)
        else
          match(*args, **rest)
        end
      end

      def marshal_load(pattern)
        initialize pattern
      end

      def marshal_dump
        pattern
      end

      def ==(other)
        other.is_a?(NodePattern) &&
          Compiler.tokens(other.pattern) == Compiler.tokens(pattern)
      end
      alias eql? ==

      def to_s
        "#<#{self.class} #{pattern}>"
      end

      # Yields its argument and any descendants, depth-first.
      #
      def self.descend(element, &block)
        return to_enum(__method__, element) unless block_given?

        yield element

        if element.is_a?(::RuboCop::AST::Node)
          element.children.each do |child|
            descend(child, &block)
          end
        end

        nil
      end

      # @api private
      class Matcher
        def initialize(&block)
          @block = block
        end

        def ===(compare)
          @block.call(compare)
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/CyclomaticComplexity
