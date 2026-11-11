# frozen_string_literal: true

module RuboCop
  module AST
    # Builds a `RuboCop::AST::Node` tree directly from a Prism syntax tree.
    #
    # `Prism::Translation::Parser` gets to the same tree by replaying the Prism
    # nodes as lexer tokens into `Parser::Builders::Default`. This class skips
    # both steps: it visits the Prism nodes and creates the final nodes and
    # their source maps itself. The resulting tree is meant to be identical to
    # the one the translation layer produces, node for node and range for range.
    #
    # It still relies on the `parser` gem for `Parser::Source::Range` and the
    # `Parser::Source::Map` classes.
    #
    # @api private
    # rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    # rubocop:disable Metrics/ParameterLists
    # rubocop:disable InternalAffairs/NodeFirstOrLastArgument -- these are prism nodes
    class PrismCompiler < ::Prism::Compiler
      Range = ::Parser::Source::Range
      Map = ::Parser::Source::Map
      Collection = Map::Collection
      Operator = Map::Operator
      Variable = Map::Variable
      Constant = Map::Constant
      Send = Map::Send
      Keyword = Map::Keyword
      Condition = Map::Condition
      NODE_MAP = BuilderExtensions::NODE_MAP
      EMPTY = [].freeze
      BLOCK_CALL_TYPES = %i[send csend index super zsuper lambda].freeze
      PERCENT_ARRAY = %w[%w %W %i %I].freeze
      private_constant :Range, :Map, :Collection, :Operator, :Variable, :Constant, :Send,
                       :Keyword, :Condition, :NODE_MAP, :EMPTY, :BLOCK_CALL_TYPES, :PERCENT_ARRAY

      DUPLICATE_KEY_TYPES = %i[sym str int float rational complex regexp].freeze
      # Prism 1 has the translation layer turn `- 1` into a negative literal,
      # Prism 2 keeps it as the method call that it is.
      NEGATE_SEPARATED_NUMERIC = ::Prism::VERSION.start_with?('1.')
      private_constant :DUPLICATE_KEY_TYPES, :NEGATE_SEPARATED_NUMERIC

      # @param source_buffer [Parser::Source::Buffer]
      # @param offset_cache [Array<Integer>, #call] maps byte offsets to
      #   character offsets, an array when the source has multibyte characters
      # @param diagnostics [Parser::Diagnostic::Engine, nil] receives what
      #   prism does not report itself: invalid regexps and duplicate hash keys
      def initialize(source_buffer, offset_cache, diagnostics = nil)
        super()
        @diagnostics = diagnostics
        @buffer = source_buffer
        @source = source_buffer.source
        @offsets = offset_cache.is_a?(Array) ? offset_cache : nil
        @forwarding = EMPTY
        @in_destructure = false
        @in_pattern = false
      end

      # alias foo bar
      def visit_alias_method_node(node)
        names = [visit(node.new_name), visit(node.old_name)]
        n(:alias, names, keyword_map(r(node.keyword_loc), nil, names, nil))
      end
      alias visit_alias_global_variable_node visit_alias_method_node

      # foo => bar | baz
      def visit_alternation_pattern_node(node)
        binary(:match_alt, visit(node.left), r(node.operator_loc), visit(node.right))
      end

      # a and b
      def visit_and_node(node)
        binary(:and, visit(node.left), r(node.operator_loc), visit(node.right))
      end

      # a or b
      def visit_or_node(node)
        binary(:or, visit(node.left), r(node.operator_loc), visit(node.right))
      end

      # []
      def visit_array_node(node)
        opening = node.opening
        elements =
          if opening&.start_with?(*PERCENT_ARRAY)
            percent_array_elements(node, opening)
          else
            visit_all(node.elements)
          end

        n(:array, elements, collection_map(r(node.opening_loc), elements, r(node.closing_loc)))
      end

      # foo => [bar]
      def visit_array_pattern_node(node)
        elements = [*node.requireds]
        implicit_rest = node.rest.is_a?(::Prism::ImplicitRestNode)
        elements << node.rest if node.rest && !implicit_rest
        elements.concat(node.posts)
        visited = visit_all(elements)
        opening = r(node.opening_loc)
        closing = r(node.closing_loc)
        tail = implicit_rest ? visited.last.loc.expression.join(r(node.rest.location)) : nil

        return array_pattern(opening, visited, closing, tail) unless node.constant

        pattern =
          if visited.empty?
            array_pattern(opening, visited, closing, tail)
          else
            array_pattern(nil, visited, nil, tail)
          end
        const_pattern(visit(node.constant), opening, pattern, closing)
      end

      # foo(bar)
      def visit_arguments_node(node)
        visit_all(node.arguments)
      end

      # { a: 1 }
      def visit_assoc_node(node)
        key = node.key
        value = node.value

        if value.is_a?(::Prism::ImplicitNode)
          implicit_assoc(key, value)
        elsif node.operator_loc
          binary(:pair, visit(key), r(node.operator_loc), visit(value))
        elsif key.is_a?(::Prism::SymbolNode) && key.opening_loc.nil?
          pair_keyword(key.unescaped, r(key.location), visit(value))
        else
          parts = key.is_a?(::Prism::SymbolNode) ? quoted_key_parts(key) : visit_all(key.parts)
          pair_quoted(r(key.opening_loc), parts, r(key.closing_loc), visit(value))
        end
      end

      # { **foo }
      def visit_assoc_splat_node(node)
        operator = r(node.operator_loc)

        if @in_pattern
          match_rest(operator, node.value&.location)
        elsif node.value.nil? && @forwarding.include?(:**)
          n(:forwarded_kwrestarg, EMPTY, Map.new(operator))
        else
          value = visit(node.value)
          n(:kwsplat, [value], unary_op_map(operator, value))
        end
      end

      # $+
      def visit_back_reference_read_node(node)
        n(:back_ref, [node.slice.to_sym], Map.new(r(node.location)))
      end

      # begin end
      def visit_begin_node(node)
        rescue_bodies = []
        rescue_clause = node.rescue_clause

        while rescue_clause
          rescue_bodies << rescue_clause_body(node, rescue_clause)
          rescue_clause = rescue_clause.subsequent
        end

        else_clause = node.else_clause
        ensure_clause = node.ensure_clause
        body = begin_body(
          visit(node.statements), rescue_bodies,
          r(else_clause&.else_keyword_loc), visit(else_clause),
          r(ensure_clause&.ensure_keyword_loc), visit(ensure_clause&.statements)
        )

        return body unless node.begin_keyword_loc

        begin_keyword(r(node.begin_keyword_loc), body, r(node.end_keyword_loc))
      end

      # foo(&bar)
      def visit_block_argument_node(node)
        expression = visit(node.expression)
        n(:block_pass, [expression], unary_op_map(r(node.operator_loc), expression))
      end

      # foo { |; bar| }
      def visit_block_local_variable_node(node)
        n(:shadowarg, [node.name], Variable.new(r(node.location)))
      end

      # def foo(&bar); end
      def visit_block_parameter_node(node)
        n(:blockarg, [node.name], arg_prefix_map(r(node.operator_loc), r(node.name_loc)))
      end

      # A block's parameters.
      def visit_block_parameters_node(node)
        [*visit(node.parameters)].concat(visit_all(node.locals))
      end

      # break foo
      def visit_break_node(node)
        keyword_cmd(:break, r(node.keyword_loc), nil, visit(node.arguments) || [], nil)
      end

      # next foo
      def visit_next_node(node)
        keyword_cmd(:next, r(node.keyword_loc), nil, visit(node.arguments) || [], nil)
      end

      # return foo
      def visit_return_node(node)
        keyword_cmd(:return, r(node.keyword_loc), nil, visit(node.arguments) || [], nil)
      end

      # foo.bar() {}
      def visit_call_node(node)
        name = node.name
        arguments = node.arguments&.arguments || EMPTY
        block = node.block

        if block.is_a?(::Prism::BlockArgumentNode)
          arguments = [*arguments, block]
          block = nil
        end

        if node.call_operator_loc.nil?
          special = visit_special_call(node, name, arguments, block)
          return special if special
        end

        message_loc = node.message_loc
        dot = r(node.call_operator_loc)
        type = node.safe_navigation? ? :csend : :send
        receiver = visit(node.receiver)

        call =
          if name.end_with?('=') && node.arguments && block.nil? &&
             !message_loc.slice.end_with?('=')
            target = n(type, [receiver, name], send_map(receiver, dot, r(message_loc)))
            assign(target, r(node.equal_loc), visit(node.arguments.arguments.last))
          else
            args = visit_all(arguments)
            map = send_map(receiver, dot, r(message_loc), r(node.opening_loc), args,
                           r(node.closing_loc))
            n(type, [receiver, name, *args], map)
          end

        with_block(call, block)
      end

      # foo.bar += baz
      def visit_call_operator_write_node(node)
        op_assign(call_write_target(node), node.binary_operator, r(node.binary_operator_loc),
                  visit(node.value))
      end

      # foo.bar &&= baz
      def visit_call_and_write_node(node)
        op_assign(call_write_target(node), :'&&', r(node.operator_loc), visit(node.value))
      end

      # foo.bar ||= baz
      def visit_call_or_write_node(node)
        op_assign(call_write_target(node), :'||', r(node.operator_loc), visit(node.value))
      end

      # foo.bar, = 1
      def visit_call_target_node(node)
        receiver = visit(node.receiver)
        type = node.safe_navigation? ? :csend : :send
        map = send_map(receiver, r(node.call_operator_loc), r(node.message_loc))
        n(type, [receiver, node.name], map)
      end

      # foo => bar => baz
      def visit_capture_pattern_node(node)
        binary(:match_as, visit(node.value), r(node.operator_loc), visit(node.target))
      end

      # case foo; when bar; end
      def visit_case_node(node)
        predicate = visit(node.predicate)
        else_keyword = r(node.else_clause&.else_keyword_loc)
        else_body = visit(node.else_clause)
        map = condition_map(r(node.case_keyword_loc), predicate, nil, nil, else_keyword,
                            else_body, r(node.end_keyword_loc))
        n(:case, [predicate, *visit_all(node.conditions), else_body], map)
      end

      # case foo; in bar; end
      def visit_case_match_node(node)
        predicate = visit(node.predicate)
        else_keyword = r(node.else_clause&.else_keyword_loc)
        else_body = visit(node.else_clause)
        else_body = n(:empty_else, EMPTY, Map.new(else_keyword)) if else_keyword && !else_body
        map = condition_map(r(node.case_keyword_loc), predicate, nil, nil, else_keyword,
                            else_body, r(node.end_keyword_loc))
        n(:case_match, [predicate, *visit_all(node.conditions), else_body], map)
      end

      # class Foo; end
      def visit_class_node(node)
        name = visit(node.constant_path)
        superclass = visit(node.superclass)
        body = with_forwarding(EMPTY) { visit(node.body) }
        map = Map::Definition.new(r(node.class_keyword_loc), r(node.inheritance_operator_loc),
                                  name.loc.expression, r(node.end_keyword_loc))
        n(:class, [name, superclass, body], map)
      end

      # module Foo; end
      def visit_module_node(node)
        name = visit(node.constant_path)
        body = with_forwarding(EMPTY) { visit(node.body) }
        map = Map::Definition.new(r(node.module_keyword_loc), nil, name.loc.expression,
                                  r(node.end_keyword_loc))
        n(:module, [name, body], map)
      end

      # class << self; end
      def visit_singleton_class_node(node)
        expression = visit(node.expression)
        body = with_forwarding(EMPTY) { visit(node.body) }
        map = Map::Definition.new(r(node.class_keyword_loc), r(node.operator_loc), nil,
                                  r(node.end_keyword_loc))
        n(:sclass, [expression, body], map)
      end

      # @@foo, @foo, $foo
      def visit_class_variable_read_node(node)
        n(:cvar, [node.name], Variable.new(r(node.location)))
      end

      def visit_instance_variable_read_node(node)
        n(:ivar, [node.name], Variable.new(r(node.location)))
      end

      def visit_global_variable_read_node(node)
        n(:gvar, [node.name], Variable.new(r(node.location)))
      end

      # foo
      def visit_local_variable_read_node(node)
        n(:lvar, [node.name], Variable.new(r(node.location)))
      end

      # -> { it }
      def visit_it_local_variable_read_node(node)
        n(:lvar, [:it], Variable.new(r(node.location)))
      end

      # @@foo = 1, @foo = 1, $foo = 1, foo = 1
      def visit_class_variable_write_node(node)
        variable_write(:cvasgn, node)
      end

      def visit_instance_variable_write_node(node)
        variable_write(:ivasgn, node)
      end

      def visit_global_variable_write_node(node)
        variable_write(:gvasgn, node)
      end

      def visit_local_variable_write_node(node)
        variable_write(:lvasgn, node)
      end

      # @@foo += bar and friends
      def visit_class_variable_operator_write_node(node)
        variable_operator_write(:cvasgn, node)
      end

      def visit_instance_variable_operator_write_node(node)
        variable_operator_write(:ivasgn, node)
      end

      def visit_global_variable_operator_write_node(node)
        variable_operator_write(:gvasgn, node)
      end

      def visit_local_variable_operator_write_node(node)
        variable_operator_write(:lvasgn, node)
      end

      # @@foo &&= bar and friends
      def visit_class_variable_and_write_node(node)
        variable_logical_write(:cvasgn, :'&&', node)
      end

      def visit_instance_variable_and_write_node(node)
        variable_logical_write(:ivasgn, :'&&', node)
      end

      def visit_global_variable_and_write_node(node)
        variable_logical_write(:gvasgn, :'&&', node)
      end

      def visit_local_variable_and_write_node(node)
        variable_logical_write(:lvasgn, :'&&', node)
      end

      # @@foo ||= bar and friends
      def visit_class_variable_or_write_node(node)
        variable_logical_write(:cvasgn, :'||', node)
      end

      def visit_instance_variable_or_write_node(node)
        variable_logical_write(:ivasgn, :'||', node)
      end

      def visit_global_variable_or_write_node(node)
        variable_logical_write(:gvasgn, :'||', node)
      end

      def visit_local_variable_or_write_node(node)
        variable_logical_write(:lvasgn, :'||', node)
      end

      # @@foo, = bar and friends
      def visit_class_variable_target_node(node)
        n(:cvasgn, [node.name], Variable.new(r(node.location)))
      end

      def visit_instance_variable_target_node(node)
        n(:ivasgn, [node.name], Variable.new(r(node.location)))
      end

      def visit_global_variable_target_node(node)
        n(:gvasgn, [node.name], Variable.new(r(node.location)))
      end

      def visit_local_variable_target_node(node)
        type = @in_pattern ? :match_var : :lvasgn
        n(type, [node.name], Variable.new(r(node.location)))
      end

      # Foo
      def visit_constant_read_node(node)
        range = r(node.location)
        n(:const, [nil, node.name], Constant.new(nil, range, range))
      end

      # Foo = 1
      def visit_constant_write_node(node)
        value = visit(node.value)
        name = r(node.name_loc)
        map = Constant.new(nil, name, name.join(value.loc.expression))
        map.send(:update_operator, r(node.operator_loc))
        n(:casgn, [nil, node.name, value], map)
      end

      # Foo += bar
      def visit_constant_operator_write_node(node)
        op_assign(constant_target(node.name, r(node.name_loc)), node.binary_operator,
                  r(node.binary_operator_loc), visit(node.value))
      end

      # Foo &&= bar
      def visit_constant_and_write_node(node)
        op_assign(constant_target(node.name, r(node.name_loc)), :'&&', r(node.operator_loc),
                  visit(node.value))
      end

      # Foo ||= bar
      def visit_constant_or_write_node(node)
        op_assign(constant_target(node.name, r(node.name_loc)), :'||', r(node.operator_loc),
                  visit(node.value))
      end

      # Foo, = bar
      def visit_constant_target_node(node)
        constant_target(node.name, r(node.location))
      end

      # Foo::Bar
      def visit_constant_path_node(node)
        constant_path(:const, node)
      end

      # Foo::Bar = 1
      def visit_constant_path_write_node(node)
        assign(constant_path(:casgn, node.target), r(node.operator_loc), visit(node.value))
      end

      # Foo::Bar += baz
      def visit_constant_path_operator_write_node(node)
        op_assign(constant_path(:casgn, node.target), node.binary_operator,
                  r(node.binary_operator_loc), visit(node.value))
      end

      # Foo::Bar &&= baz
      def visit_constant_path_and_write_node(node)
        op_assign(constant_path(:casgn, node.target), :'&&', r(node.operator_loc),
                  visit(node.value))
      end

      # Foo::Bar ||= baz
      def visit_constant_path_or_write_node(node)
        op_assign(constant_path(:casgn, node.target), :'||', r(node.operator_loc),
                  visit(node.value))
      end

      # Foo::Bar, = baz
      def visit_constant_path_target_node(node)
        constant_path(:casgn, node)
      end

      # def foo; end
      def visit_def_node(node)
        parameters = node.parameters
        params = visit(parameters) || []
        args = n(:args, params, collection_map(r(node.lparen_loc), params, r(node.rparen_loc)))
        body = with_forwarding(find_forwarding(parameters)) { visit(node.body) }
        keyword = r(node.def_keyword_loc)
        name = r(node.name_loc)
        operator = r(node.operator_loc)

        map =
          if node.equal_loc
            Map::MethodDefinition.new(keyword, operator, name, nil, r(node.equal_loc),
                                      body.loc.expression)
          else
            Map::MethodDefinition.new(keyword, operator, name, r(node.end_keyword_loc), nil, nil)
          end

        # The `parser` AST keeps the `@` of `def !@` and `def ~@` in the name.
        method_name = node.name
        method_name = node.name_loc.slice.to_sym if %i[! ~].include?(method_name)
        receiver = node.receiver
        return n(:def, [method_name, args, body], map) unless receiver

        receiver = receiver.body if receiver.is_a?(::Prism::ParenthesesNode)
        n(:defs, [visit(receiver), method_name, args, body], map)
      end

      # defined?(a)
      def visit_defined_node(node)
        keyword = r(node.keyword_loc)
        lparen = r(node.lparen_loc)
        rparen = r(node.rparen_loc)
        value = visit(node.value)

        # `defined?` followed by a parenthesized expression on the next line
        # keeps the parentheses as a `begin` node.
        if lparen && node.keyword_loc.join(node.lparen_loc).slice.include?("\n")
          keyword_cmd(:defined?, keyword, nil, [begin_node(lparen, value, rparen)], nil)
        else
          keyword_cmd(:defined?, keyword, lparen, [value], rparen)
        end
      end

      # if foo then bar else baz end
      #                 ^^^^^^^^^^^^
      def visit_else_node(node)
        visit(node.statements)
      end

      # "foo #{bar}"
      #      ^^^^^^
      def visit_embedded_statements_node(node)
        begin_node(r(node.opening_loc), visit(node.statements), r(node.closing_loc))
      end

      # "foo #@bar"
      def visit_embedded_variable_node(node)
        visit(node.variable)
      end

      # ()
      def visit_parentheses_node(node)
        begin_node(r(node.opening_loc), visit(node.body), r(node.closing_loc))
      end

      # false, true, nil, self
      def visit_false_node(node)
        n(:false, EMPTY, Map.new(r(node.location)))
      end

      def visit_true_node(node)
        n(:true, EMPTY, Map.new(r(node.location)))
      end

      def visit_nil_node(node)
        n(:nil, EMPTY, Map.new(r(node.location)))
      end

      def visit_self_node(node)
        n(:self, EMPTY, Map.new(r(node.location)))
      end

      # foo => [*, bar, *]
      def visit_find_pattern_node(node)
        elements = visit_all([node.left, *node.requireds, node.right])
        opening = r(node.opening_loc)
        closing = r(node.closing_loc)

        if node.constant
          pattern = n(:find_pattern, elements, collection_map(nil, elements, nil))
          const_pattern(visit(node.constant), opening, pattern, closing)
        else
          n(:find_pattern, elements, collection_map(opening, elements, closing))
        end
      end

      # foo => {}
      def visit_hash_pattern_node(node)
        elements = visit_all([*node.elements, *node.rest])
        opening = r(node.opening_loc)
        closing = r(node.closing_loc)

        if node.constant
          pattern = n(:hash_pattern, elements, collection_map(nil, elements, nil))
          const_pattern(visit(node.constant), opening, pattern, closing)
        else
          n(:hash_pattern, elements, collection_map(opening, elements, closing))
        end
      end

      # 1, 1.0, 1r, 1i
      def visit_integer_node(node)
        numeric(:int, node, node.value)
      end

      def visit_float_node(node)
        numeric(:float, node, node.value)
      end

      def visit_rational_node(node)
        numeric(:rational, node, node.value)
      end

      def visit_imaginary_node(node)
        numeric(:complex, node, Complex(0, node.numeric.value))
      end

      # for foo in bar do end
      def visit_for_node(node)
        do_keyword =
          if node.do_keyword_loc
            r(node.do_keyword_loc)
          else
            semicolon(node.collection.location.end_offset,
                      (node.statements&.location || node.end_keyword_loc).start_offset)
          end
        keyword = r(node.for_keyword_loc)
        end_keyword = r(node.end_keyword_loc)
        map = Map::For.new(keyword, r(node.in_keyword_loc), do_keyword, end_keyword,
                           keyword.join(end_keyword))
        n(:for, [visit(node.index), visit(node.collection), visit(node.statements)], map)
      end

      # def foo(...); bar(...); end
      #                   ^^^
      def visit_forwarding_arguments_node(node)
        n(:forwarded_args, EMPTY, Map.new(r(node.location)))
      end

      # def foo(...); end
      #         ^^^
      def visit_forwarding_parameter_node(node)
        n(:forward_arg, EMPTY, Map.new(r(node.location)))
      end

      # super {}
      def visit_forwarding_super_node(node)
        start = node.location.start_offset
        with_block(keyword_cmd(:zsuper, ro(start, start + 5), nil, EMPTY, nil), node.block)
      end

      # super(foo)
      def visit_super_node(node)
        arguments = node.arguments&.arguments || EMPTY
        block = node.block

        if block.is_a?(::Prism::BlockArgumentNode)
          arguments = [*arguments, block]
          block = nil
        end

        call = keyword_cmd(:super, r(node.keyword_loc), r(node.lparen_loc),
                           visit_all(arguments), r(node.rparen_loc))
        with_block(call, block)
      end

      # yield 1
      def visit_yield_node(node)
        keyword_cmd(:yield, r(node.keyword_loc), r(node.lparen_loc),
                    visit(node.arguments) || [], r(node.rparen_loc))
      end

      # {}
      def visit_hash_node(node)
        pairs = visit_all(node.elements)
        check_duplicate_keys(pairs)
        n(:hash, pairs, collection_map(r(node.opening_loc), pairs, r(node.closing_loc)))
      end

      # foo(bar: baz)
      #     ^^^^^^^^
      def visit_keyword_hash_node(node)
        pairs = visit_all(node.elements)
        check_duplicate_keys(pairs)
        n(:hash, pairs, collection_map(nil, pairs, nil))
      end

      # if foo then bar end, bar if foo, foo ? bar : baz
      def visit_if_node(node)
        predicate = visit(node.predicate)
        statements = visit(node.statements)
        subsequent = node.subsequent
        if_false = visit(subsequent)
        children = [check_condition(predicate), statements, if_false]

        map =
          if !node.if_keyword_loc
            Map::Ternary.new(r(node.then_keyword_loc), r(subsequent.else_keyword_loc),
                             join(predicate, if_false))
          elsif node.if_keyword_loc.start_offset == node.location.start_offset
            if_statement_map(node, predicate, statements, if_false)
          else
            Keyword.new(r(node.if_keyword_loc), nil, nil, join(statements || if_false, predicate))
          end
        n(:if, children, map)
      end

      # unless foo; bar end, bar unless foo
      def visit_unless_node(node)
        predicate = visit(node.predicate)
        statements = visit(node.statements)
        else_clause = node.else_clause
        if_true = visit(else_clause)
        children = [check_condition(predicate), if_true, statements]

        unless node.keyword_loc.start_offset == node.location.start_offset
          map = Keyword.new(r(node.keyword_loc), nil, nil, join(if_true || statements, predicate))
          return n(:if, children, map)
        end

        then_keyword =
          if node.then_keyword_loc
            r(node.then_keyword_loc)
          else
            semicolon(node.predicate.location.end_offset,
                      (node.statements&.location || else_clause&.location ||
                       node.end_keyword_loc).start_offset)
          end
        map = condition_map(r(node.keyword_loc), predicate, then_keyword, if_true,
                            r(else_clause&.else_keyword_loc), statements,
                            r(node.end_keyword_loc))
        n(:if, children, map)
      end

      # case foo; in bar; end
      #           ^^^^^^
      def visit_in_node(node)
        pattern_node = node.pattern
        guard = nil

        case pattern_node
        when ::Prism::IfNode
          pattern = within_pattern { visit(pattern_node.statements) }
          guard = guard_node(:if_guard, r(pattern_node.if_keyword_loc), visit(pattern_node.predicate))
        when ::Prism::UnlessNode
          pattern = within_pattern { visit(pattern_node.statements) }
          guard = guard_node(:unless_guard, r(pattern_node.keyword_loc),
                             visit(pattern_node.predicate))
        else
          pattern = within_pattern { visit(pattern_node) }
        end

        then_keyword =
          if node.then_loc
            r(node.then_loc)
          else
            semicolon(pattern_node.location.end_offset, node.statements&.location&.start_offset)
          end
        children = [pattern, guard, visit(node.statements)]
        n(:in_pattern, children, keyword_map(r(node.in_loc), then_keyword, children.compact, nil))
      end

      # foo[bar] += baz
      def visit_index_operator_write_node(node)
        op_assign(index_write_target(node), node.binary_operator, r(node.binary_operator_loc),
                  visit(node.value))
      end

      # foo[bar] &&= baz
      def visit_index_and_write_node(node)
        op_assign(index_write_target(node), :'&&', r(node.operator_loc), visit(node.value))
      end

      # foo[bar] ||= baz
      def visit_index_or_write_node(node)
        op_assign(index_write_target(node), :'||', r(node.operator_loc), visit(node.value))
      end

      # foo[bar], = 1
      def visit_index_target_node(node)
        index(:[]=, visit(node.receiver), r(node.opening_loc),
              visit_all(node.arguments&.arguments || EMPTY), r(node.closing_loc))
      end

      # /foo #{bar}/
      def visit_interpolated_regular_expression_node(node)
        regexp(node, string_nodes_from_interpolation(node, node.opening))
      end
      alias visit_interpolated_match_last_line_node visit_interpolated_regular_expression_node

      # /foo/
      def visit_regular_expression_node(node)
        content = node.content
        parts =
          if content.empty?
            []
          elsif content.include?("\n")
            string_nodes_from_line_continuations(node.unescaped, content,
                                                 node.content_loc.start_offset, node.opening)
          else
            [str_internal(node.unescaped, r(node.content_loc))]
          end
        regexp(node, parts)
      end
      alias visit_match_last_line_node visit_regular_expression_node

      # "foo #{bar}"
      def visit_interpolated_string_node(node)
        opening = r(node.opening_loc)
        if node.heredoc?
          return visit_heredoc(node) do |children, closing|
            string_compose(opening, children, closing, heredoc: true)
          end
        end

        string_compose(opening, string_nodes_from_interpolation(node, node.opening),
                       r(node.closing_loc))
      end

      # :"foo #{bar}"
      def visit_interpolated_symbol_node(node)
        symbol_compose(r(node.opening_loc), string_nodes_from_interpolation(node, node.opening),
                       r(node.closing_loc))
      end

      # `foo #{bar}`
      def visit_interpolated_x_string_node(node)
        opening = r(node.opening_loc)
        if node.heredoc?
          return visit_heredoc(node) do |children, closing|
            n(:xstr, children, string_map(opening, children, closing, heredoc: true))
          end
        end

        parts = string_nodes_from_interpolation(node, node.opening)
        n(:xstr, parts, string_map(opening, parts, r(node.closing_loc)))
      end

      # "foo"
      def visit_string_node(node)
        opening_loc = node.opening_loc
        opening = r(opening_loc)

        if node.heredoc?
          visit_heredoc(node.to_interpolated) do |children, closing|
            string_compose(opening, children, closing, heredoc: true)
          end
        elsif opening_loc.nil?
          content = node.content
          if content.include?("\n")
            parts = string_nodes_from_line_continuations(node.unescaped, content,
                                                         node.content_loc.start_offset, nil)
            string_compose(nil, parts, nil)
          else
            str_internal(node.unescaped, r(node.content_loc))
          end
        else
          visit_delimited_string_node(node, opening)
        end
      end

      # `foo`
      def visit_x_string_node(node)
        opening = r(node.opening_loc)
        if node.heredoc?
          return visit_heredoc(node.to_interpolated) do |children, closing|
            n(:xstr, children, string_map(opening, children, closing, heredoc: true))
          end
        end

        content = node.content
        parts =
          if content.empty?
            []
          elsif content.include?("\n")
            string_nodes_from_line_continuations(node.unescaped, content,
                                                 node.content_loc.start_offset, node.opening)
          else
            [str_internal(node.unescaped, r(node.content_loc))]
          end
        n(:xstr, parts, string_map(opening, parts, r(node.closing_loc)))
      end

      # :foo
      def visit_symbol_node(node)
        if node.closing_loc.nil?
          range = r(node.location)
          map =
            if node.opening_loc.nil?
              Collection.new(nil, nil, range)
            else
              Collection.new(range.with(end_pos: range.begin_pos + 1), nil, range)
            end
          return n(:sym, [node.unescaped.to_sym], map)
        end

        value = node.value
        parts =
          if value.empty?
            []
          elsif value.include?("\n")
            string_nodes_from_line_continuations(node.unescaped, value,
                                                 node.value_loc.start_offset, node.opening)
          else
            [str_internal(node.unescaped, r(node.value_loc))]
          end
        symbol_compose(r(node.opening_loc), parts, r(node.closing_loc))
      end

      # -> {}
      def visit_lambda_node(node)
        operator = r(node.operator_loc)
        call = n(:send, [nil, :lambda], Send.new(nil, operator, nil, nil, operator))
        block_node(call, r(node.opening_loc), node.parameters, visit(node.body), r(node.closing_loc))
      end

      # foo in bar
      def visit_match_predicate_node(node)
        value = visit(node.value)
        pattern = within_pattern { visit(node.pattern) }
        binary(:match_pattern_p, value, r(node.operator_loc), pattern)
      end

      # foo => bar
      def visit_match_required_node(node)
        value = visit(node.value)
        pattern = within_pattern { visit(node.pattern) }
        binary(:match_pattern, value, r(node.operator_loc), pattern)
      end

      # /(?<foo>foo)/ =~ bar
      def visit_match_write_node(node)
        call = node.call
        match_op(visit(call.receiver), r(call.message_loc), visit(call.arguments.arguments.first))
      end

      # A node that is missing from the syntax tree, only seen for invalid code.
      def visit_missing_node(node)
        n(:missing, EMPTY, Map.new(r(node.location)))
      end
      alias visit_error_recovery_node visit_missing_node # the name since Prism 2

      # foo, bar = baz
      # ^^^^^^^^
      def visit_multi_target_node(node)
        items = visit_all(multi_target_elements(node))
        n(:mlhs, items, collection_map(r(node.lparen_loc), items, r(node.rparen_loc)))
      end

      # foo, bar = baz
      def visit_multi_write_node(node)
        elements = multi_target_elements(node)
        if elements.length == 1 && elements.first.is_a?(::Prism::MultiTargetNode) && !node.rest
          elements = multi_target_elements(elements.first)
        end

        items = visit_all(elements)
        mlhs = n(:mlhs, items, collection_map(r(node.lparen_loc), items, r(node.rparen_loc)))
        binary(:masgn, mlhs, r(node.operator_loc), visit(node.value))
      end

      # def foo(&nil); end
      def visit_no_block_parameter_node(node)
        n(:blocknilarg, EMPTY, arg_prefix_map(r(node.operator_loc), r(node.keyword_loc)))
      end

      # def foo(**nil); end
      def visit_no_keywords_parameter_node(node)
        type = @in_pattern ? :match_nil_pattern : :kwnilarg
        n(type, EMPTY, arg_prefix_map(r(node.operator_loc), r(node.keyword_loc)))
      end

      # $1
      def visit_numbered_reference_read_node(node)
        n(:nth_ref, [node.number], Map.new(r(node.location)))
      end

      # def foo(bar: baz); end
      def visit_optional_keyword_parameter_node(node)
        value = visit(node.value)
        n(:kwoptarg, [node.name, value], kwarg_map(r(node.name_loc), value))
      end

      # def foo(bar:); end
      def visit_required_keyword_parameter_node(node)
        n(:kwarg, [node.name], kwarg_map(r(node.name_loc), nil))
      end

      # def foo(bar = 1); end
      def visit_optional_parameter_node(node)
        value = visit(node.value)
        name = r(node.name_loc)
        map = Variable.new(name, name.join(value.loc.expression))
        map.send(:update_operator, r(node.operator_loc))
        n(:optarg, [node.name, value], map)
      end

      # def foo(bar); end
      def visit_required_parameter_node(node)
        n(:arg, [node.name], Variable.new(r(node.location)))
      end

      # def foo(*bar); end
      def visit_rest_parameter_node(node)
        children = node.name ? [node.name] : EMPTY
        n(:restarg, children, arg_prefix_map(r(node.operator_loc), r(node.name_loc)))
      end

      # def foo(**bar); end
      def visit_keyword_rest_parameter_node(node)
        children = node.name ? [node.name] : EMPTY
        n(:kwrestarg, children, arg_prefix_map(r(node.operator_loc), r(node.name_loc)))
      end

      # def foo(bar, *baz); end
      def visit_parameters_node(node)
        params = node.requireds.map { |param| visit_positional_parameter(param) }
        node.optionals.each { |param| params << visit(param) }
        rest = node.rest
        params << visit(rest) if rest && !rest.is_a?(::Prism::ImplicitRestNode)
        node.posts.each { |param| params << visit_positional_parameter(param) }
        node.keywords.each { |param| params << visit(param) }
        params << visit(node.keyword_rest) if node.keyword_rest
        params << visit(node.block) if node.block
        params
      end

      # foo => ^(bar)
      def visit_pinned_expression_node(node)
        body = with_pattern(false) { visit(node.expression) }
        expression = begin_node(r(node.lparen_loc), body, r(node.rparen_loc))
        n(:pin, [expression], send_unary_op_map(r(node.operator_loc), expression))
      end

      # foo => ^bar
      def visit_pinned_variable_node(node)
        variable = visit(node.variable)
        n(:pin, [variable], send_unary_op_map(r(node.operator_loc), variable))
      end

      # END {}
      def visit_post_execution_node(node)
        map = keyword_map(r(node.keyword_loc), r(node.opening_loc), EMPTY, r(node.closing_loc))
        n(:postexe, [visit(node.statements)], map)
      end

      # BEGIN {}
      def visit_pre_execution_node(node)
        map = keyword_map(r(node.keyword_loc), r(node.opening_loc), EMPTY, r(node.closing_loc))
        n(:preexe, [visit(node.statements)], map)
      end

      # The top-level program node.
      def visit_program_node(node)
        visit(node.statements)
      end

      # 0..5
      def visit_range_node(node)
        left = visit(node.left)
        right = visit(node.right)
        operator = r(node.operator_loc)
        expression =
          if left && right
            join(left, right)
          elsif left
            left.loc.expression.join(operator)
          elsif right
            operator.join(right.loc.expression)
          end
        n(node.exclude_end? ? :erange : :irange, [left, right], Operator.new(operator, expression))
      end
      alias visit_flip_flop_node visit_range_node

      # redo, retry
      def visit_redo_node(node)
        keyword_cmd(:redo, r(node.location), nil, EMPTY, nil)
      end

      def visit_retry_node(node)
        keyword_cmd(:retry, r(node.location), nil, EMPTY, nil)
      end

      # foo rescue bar
      def visit_rescue_modifier_node(node)
        body = rescue_body(r(node.keyword_loc), nil, nil, nil, nil, visit(node.rescue_expression))
        begin_body(visit(node.expression), [body], nil, nil, nil, nil)
      end

      # A shareable constant.
      def visit_shareable_constant_node(node)
        visit(node.write)
      end

      # __ENCODING__, __FILE__, __LINE__
      def visit_source_encoding_node(node)
        # rubocop:disable-next Naming/VariableNumber -- the name of a Ruby constant
        n(:const, [n(:const, [nil, :Encoding], nil), :UTF_8], Map.new(r(node.location)))
      end

      def visit_source_file_node(node)
        n(:str, [@buffer.name], Map.new(r(node.location)))
      end

      def visit_source_line_node(node)
        range = r(node.location)
        n(:int, [range.line], Map.new(range))
      end

      # foo(*bar), def foo((bar, *baz)); end
      def visit_splat_node(node)
        operator = r(node.operator_loc)
        expression = node.expression

        if expression.nil? && @forwarding.include?(:*)
          n(:forwarded_restarg, EMPTY, Map.new(operator))
        elsif @in_destructure
          children = expression ? [expression.slice.to_sym] : EMPTY
          n(:restarg, children, arg_prefix_map(operator, r(expression&.location)))
        elsif @in_pattern
          match_rest(operator, expression&.location)
        else
          value = visit(expression)
          n(:splat, value ? [value] : EMPTY, unary_op_map(operator, value))
        end
      end

      # A list of statements.
      def visit_statements_node(node)
        body = node.body
        return visit(body.first) if body.size == 1

        statements = visit_all(body)
        return if statements.empty?

        n(:begin, statements, collection_map(nil, statements, nil))
      end

      # undef foo
      def visit_undef_node(node)
        names = visit_all(node.names)
        n(:undef, names, keyword_map(r(node.keyword_loc), nil, names, nil))
      end

      # until foo; bar end, bar until foo
      def visit_until_node(node)
        visit_loop(:until, node)
      end

      # while foo; bar end, bar while foo
      def visit_while_node(node)
        visit_loop(:while, node)
      end

      # case foo; when bar; end
      #           ^^^^^^^^^^^^^
      def visit_when_node(node)
        then_keyword =
          if node.then_keyword_loc
            r(node.then_keyword_loc)
          else
            semicolon(node.conditions.last.location.end_offset,
                      node.statements&.location&.start_offset)
          end
        children = visit_all(node.conditions) << visit(node.statements)
        n(:when, children, keyword_map(r(node.keyword_loc), then_keyword, children, nil))
      end

      %i[
        block ensure implicit implicit_rest rescue it_parameters numbered_parameters
      ].each do |name|
        define_method(:"visit_#{name}_node") do |_node|
          raise ArgumentError, "Cannot directly compile #{name} nodes"
        end
      end

      private

      # --- node construction -------------------------------------------------

      def n(type, children, map)
        (NODE_MAP[type] || Node).new(type, children, location: map)
      end

      def binary(type, left, operator, right)
        n(type, [left, right], Operator.new(operator, join(left, right)))
      end

      def join(left, right)
        left.loc.expression.join(right.loc.expression)
      end

      def diagnostic(level, reason, arguments, range)
        @diagnostics&.process(::Parser::Diagnostic.new(level, reason, arguments, range))
      end

      def check_duplicate_keys(pairs)
        return if pairs.size < 2

        keys = nil
        pairs.each do |pair|
          next unless pair.pair_type?

          key = pair.children.first
          next unless DUPLICATE_KEY_TYPES.include?(key.type)
          next if (keys ||= Set.new).add?(key)

          diagnostic(:warning, :duplicate_hash_key, nil, key.loc.expression)
        end
      end

      # --- ranges ------------------------------------------------------------

      def r(location)
        return unless location

        ro(location.start_offset, location.end_offset)
      end

      def ro(start_offset, end_offset)
        if (offsets = @offsets)
          Range.new(@buffer, offsets[start_offset], offsets[end_offset])
        else
          Range.new(@buffer, start_offset, end_offset)
        end
      end

      # The range of a semicolon between the two offsets, not looking past
      # newlines or comments. `end_offset` may be nil to search to the end.
      def semicolon(start_offset, end_offset)
        match = @source.byteslice(start_offset...end_offset)[/\A\s*;/]
        return unless match

        final_offset = start_offset + match.bytesize
        ro(final_offset - 1, final_offset)
      end

      # --- source maps -------------------------------------------------------

      def collection_map(begin_l, parts, end_l)
        expression =
          if begin_l && end_l
            begin_l.join(end_l)
          elsif parts.any?
            join(parts.first, parts.last)
          else
            begin_l || end_l
          end
        Collection.new(begin_l, end_l, expression)
      end

      def string_map(begin_l, parts, end_l, heredoc: false)
        return collection_map(begin_l, parts, end_l) unless heredoc

        body = parts.any? ? join(parts.first, parts.last) : end_l.begin
        Map::Heredoc.new(begin_l, body, end_l)
      end

      def unary_op_map(operator, argument)
        expression = argument ? operator.join(argument.loc.expression) : operator
        Operator.new(operator, expression)
      end

      def send_unary_op_map(selector, argument)
        expression = argument ? selector.join(argument.loc.expression) : selector
        Send.new(nil, selector, nil, nil, expression)
      end

      def arg_prefix_map(operator, name)
        Variable.new(name, name ? operator.join(name) : operator)
      end

      def kwarg_map(label, value)
        expression = value ? label.join(value.loc.expression) : label
        Variable.new(label.adjust(end_pos: -1), expression)
      end

      def send_map(receiver, dot, selector, begin_l = nil, args = EMPTY, end_l = nil)
        start = receiver ? receiver.loc.expression : selector
        finish =
          if end_l
            end_l
          elsif args.any?
            args.last.loc.expression
          else
            selector
          end
        Send.new(dot, selector, begin_l, end_l, start.join(finish))
      end

      def keyword_map(keyword, begin_l, args, end_l)
        finish =
          if end_l
            end_l
          elsif args.any? && !args.last.nil?
            args.last.loc.expression
          elsif args.any? && args.size > 1
            args[-2].loc.expression
          else
            keyword
          end
        Keyword.new(keyword, begin_l, end_l, keyword.join(finish))
      end

      def condition_map(keyword, condition, begin_l, body, else_l, else_body, end_l)
        finish = end_l || else_body&.loc&.expression || else_l || body&.loc&.expression ||
                 begin_l || condition.loc.expression
        Condition.new(keyword, begin_l, else_l, end_l, keyword.join(finish))
      end

      def eh_keyword_map(body, keyword, bodies, else_l, else_body)
        start = body ? body.loc.expression : keyword || bodies.first.loc.expression
        finish =
          if else_l
            else_body ? else_body.loc.expression : else_l
          elsif bodies.last
            bodies.last.loc.expression
          else
            keyword
          end
        Condition.new(keyword, nil, else_l, nil, start.join(finish))
      end

      # --- compound builders -------------------------------------------------

      def keyword_cmd(type, keyword, lparen, args, rparen)
        n(type, args, keyword_map(keyword, lparen, args, rparen))
      end

      def assign(target, operator, value)
        map = target.loc.with_operator(operator).with_expression(join(target, value))
        n(target.type, [*target.children, value], map)
      end

      def op_assign(target, operator, operator_l, value)
        map = target.loc.with_operator(operator_l).with_expression(join(target, value))

        case operator
        when :'&&' then n(:and_asgn, [target, value], map)
        when :'||' then n(:or_asgn, [target, value], map)
        else n(:op_asgn, [target, operator, value], map)
        end
      end

      def variable_write(type, node)
        value = visit(node.value)
        name = r(node.name_loc)
        map = Variable.new(name, name.join(value.loc.expression))
        map.send(:update_operator, r(node.operator_loc))
        n(type, [node.name, value], map)
      end

      def variable_operator_write(type, node)
        target = n(type, [node.name], Variable.new(r(node.name_loc)))
        op_assign(target, node.binary_operator, r(node.binary_operator_loc), visit(node.value))
      end

      def variable_logical_write(type, operator, node)
        target = n(type, [node.name], Variable.new(r(node.name_loc)))
        op_assign(target, operator, r(node.operator_loc), visit(node.value))
      end

      def constant_target(name, range)
        n(:casgn, [nil, name], Constant.new(nil, range, range))
      end

      def constant_path(type, node)
        delimiter = r(node.delimiter_loc)
        name = r(node.name_loc)
        scope =
          if node.parent
            visit(node.parent)
          else
            n(:cbase, EMPTY, Map.new(delimiter))
          end
        n(type, [scope, node.name], Constant.new(delimiter, name, scope.loc.expression.join(name)))
      end

      def call_write_target(node)
        receiver = visit(node.receiver)
        type = node.safe_navigation? ? :csend : :send
        map = send_map(receiver, r(node.call_operator_loc), r(node.message_loc))
        n(type, [receiver, node.read_name], map)
      end

      def index_write_target(node)
        arguments = node.arguments&.arguments || EMPTY
        arguments = [*arguments, node.block] if node.block
        index(:[], visit(node.receiver), r(node.opening_loc), visit_all(arguments),
              r(node.closing_loc))
      end

      def index(name, receiver, lbrack, indexes, rbrack)
        map = Send.new(nil, lbrack.join(rbrack), nil, nil, receiver.loc.expression.join(rbrack))
        n(:send, [receiver, name, *indexes], map)
      end

      # The calls that do not end up as a plain `send`. Returns nil for the rest.
      def visit_special_call(node, name, arguments, block)
        case name
        when :-@
          return unless NEGATE_SEPARATED_NUMERIC

          receiver = node.receiver
          case receiver.type
          when :integer_node, :float_node, :rational_node, :imaginary_node
            visit(numeric_negate(node.message_loc, receiver))
          end
        when :!
          with_block(not_op(node), block)
        when :=~
          receiver = node.receiver
          return unless receiver.is_a?(::Prism::RegularExpressionNode)

          match_op(visit(receiver), r(node.message_loc), visit(node.arguments.arguments.first))
        when :[]
          call = index(:[], visit(node.receiver), r(node.opening_loc), visit_all(arguments),
                       r(node.closing_loc))
          with_block(call, block)
        when :[]=
          return unless node.message != '[]=' && node.arguments && block.nil?

          arguments = node.arguments.arguments[...-1]
          arguments << node.block if node.block
          target = index(:[]=, visit(node.receiver), r(node.opening_loc), visit_all(arguments),
                         r(node.closing_loc))
          with_block(assign(target, r(node.equal_loc), visit(node.arguments.arguments.last)),
                     block)
        end
      end

      def not_op(node)
        operator = r(node.message_loc)
        receiver = visit(node.receiver)
        lparen = r(node.opening_loc)
        rparen = r(node.closing_loc)

        if receiver
          map = send_map(nil, nil, operator, lparen, [receiver], rparen)
          n(:send, [check_condition(receiver), :!], map)
        else
          empty = n(:begin, EMPTY, collection_map(lparen, EMPTY, rparen))
          n(:send, [empty, :!], send_unary_op_map(operator, empty))
        end
      end

      def match_op(receiver, operator, argument)
        map = Send.new(nil, operator, nil, nil, join(receiver, argument))

        if static_regexp?(receiver)
          n(:match_with_lvasgn, [receiver, argument], map)
        else
          n(:send, [receiver, :=~, argument], map)
        end
      end

      # A regexp literal without interpolation that Ruby can compile declares
      # its named captures as local variables.
      def static_regexp?(node)
        return false unless node.regexp_type?

        parts = node.children[0...-1]
        return false unless parts.all?(&:str_type?)

        compile_regexp(parts, node.children.last)
        true
      rescue RegexpError, EncodingError
        false
      end

      def compile_regexp(parts, options)
        source = parts.map { |part| part.children.first }.join
        options = options.children
        source =
          if options.include?(:u) then source.encode(Encoding::UTF_8)
          elsif options.include?(:e) then source.encode(Encoding::EUC_JP)
          elsif options.include?(:s) then source.encode(Encoding::WINDOWS_31J)
          elsif options.include?(:n) then source.encode(Encoding::BINARY)
          else source
          end

        verbose = $VERBOSE
        $VERBOSE = nil
        Regexp.new(source, (Regexp::EXTENDED if options.include?(:x)))
      ensure
        $VERBOSE = verbose
      end

      # Conditions give regexp and range literals a different meaning.
      def check_condition(condition)
        case condition.type
        when :begin
          children = condition.children
          return condition unless children.size == 1

          checked = check_condition(children.last)
          checked.equal?(children.last) ? condition : condition.updated(nil, [checked])
        when :and, :or
          left, right = *condition
          checked_left = check_condition(left)
          checked_right = check_condition(right)
          return condition if checked_left.equal?(left) && checked_right.equal?(right)

          condition.updated(nil, [checked_left, checked_right])
        when :irange, :erange
          left, right = *condition
          type = condition.irange_type? ? :iflipflop : :eflipflop
          condition.updated(type, [left && check_condition(left),
                                   right && check_condition(right)])
        when :regexp
          n(:match_current_line, [condition], Map.new(condition.loc.expression))
        else
          condition
        end
      end

      # --- blocks ------------------------------------------------------------

      def with_block(call, prism_block)
        return call unless prism_block

        block_node(call, r(prism_block.opening_loc), prism_block.parameters, visit(prism_block.body),
                   r(prism_block.closing_loc))
      end

      def block_node(call, begin_l, parameters, body, end_l)
        type = :block
        args =
          case parameters
          when nil
            n(:args, EMPTY, Collection.new(nil, nil, nil))
          when ::Prism::NumberedParametersNode
            type = :numblock
            parameters.maximum
          when ::Prism::ItParametersNode
            type = :itblock
            :it
          else
            params = visit(parameters)
            n(:args, params,
              collection_map(r(parameters.opening_loc), params, r(parameters.closing_loc)))
          end

        if BLOCK_CALL_TYPES.include?(call.type)
          map = Collection.new(begin_l, end_l, call.loc.expression.join(end_l))
          return n(type, [call, args, body], map)
        end

        # Code like `return foo 1 do end`, where the block belongs to the
        # call that is the argument of the keyword.
        actual_send, = *call
        map = Collection.new(begin_l, end_l, actual_send.loc.expression.join(end_l))
        block = n(type, [actual_send, args, body], map)
        n(call.type, [block], call.loc.with_expression(join(call, block)))
      end

      # --- begin, rescue, ensure ---------------------------------------------

      def begin_node(begin_l, body, end_l)
        if body.nil?
          n(:begin, EMPTY, collection_map(begin_l, EMPTY, end_l))
        elsif body.mlhs_type? ||
              (body.begin_type? && body.loc.begin.nil? && body.loc.end.nil?)
          n(body.type, body.children, collection_map(begin_l, body.children, end_l))
        else
          n(:begin, [body], collection_map(begin_l, [body], end_l))
        end
      end

      def begin_keyword(begin_l, body, end_l)
        if body.nil?
          n(:kwbegin, EMPTY, collection_map(begin_l, EMPTY, end_l))
        elsif body.begin_type? && body.loc.begin.nil? && body.loc.end.nil?
          n(:kwbegin, body.children, collection_map(begin_l, body.children, end_l))
        else
          n(:kwbegin, [body], collection_map(begin_l, [body], end_l))
        end
      end

      def rescue_clause_body(node, clause)
        start_offset = (clause.reference&.location || clause.exceptions.last&.location ||
                        clause.keyword_loc).end_offset
        end_offset = clause.statements&.location&.start_offset ||
                     clause.subsequent&.location&.start_offset ||
                     node.else_clause&.location&.start_offset ||
                     node.ensure_clause&.location&.start_offset ||
                     node.end_keyword_loc&.start_offset ||
                     (start_offset + 1)
        exceptions = clause.exceptions
        list =
          if exceptions.any?
            visited = visit_all(exceptions)
            n(:array, visited, collection_map(nil, visited, nil))
          end

        rescue_body(r(clause.keyword_loc), list, r(clause.operator_loc), visit(clause.reference),
                    semicolon(start_offset, end_offset), visit(clause.statements))
      end

      def rescue_body(keyword, exceptions, assoc, variable, then_l, body)
        finish = body&.loc&.expression || then_l || variable&.loc&.expression ||
                 exceptions&.loc&.expression || keyword
        map = Map::RescueBody.new(keyword, assoc, then_l, keyword.join(finish))
        n(:resbody, [exceptions, variable, body], map)
      end

      def begin_body(body, rescue_bodies, else_l, else_body, ensure_l, ensure_body)
        if rescue_bodies.any?
          map = eh_keyword_map(body, nil, rescue_bodies, else_l, else_l ? else_body : nil)
          body = n(:rescue, [body, *rescue_bodies, else_l ? else_body : nil], map)
        elsif else_l
          statements = []
          if body
            body.begin_type? ? statements.concat(body.children) : statements << body
          end
          statements << n(:begin, [else_body], collection_map(else_l, [else_body], nil))
          body = n(:begin, statements, collection_map(nil, statements, nil))
        end

        return body unless ensure_l

        n(:ensure, [body, ensure_body],
          eh_keyword_map(body, ensure_l, [ensure_body], nil, nil))
      end

      # --- conditionals ------------------------------------------------------

      def if_statement_map(node, predicate, statements, if_false)
        subsequent = node.subsequent
        then_keyword =
          if node.then_keyword_loc
            r(node.then_keyword_loc)
          else
            semicolon(node.predicate.location.end_offset,
                      (node.statements&.location || subsequent&.location ||
                       node.end_keyword_loc).start_offset)
          end
        else_keyword =
          case subsequent
          when ::Prism::IfNode then r(subsequent.if_keyword_loc)
          when ::Prism::ElseNode then r(subsequent.else_keyword_loc)
          end
        end_keyword = node.if_keyword == 'elsif' ? nil : r(node.end_keyword_loc)
        condition_map(r(node.if_keyword_loc), predicate, then_keyword, statements,
                      else_keyword, if_false, end_keyword)
      end

      # --- loops -------------------------------------------------------------

      def visit_loop(type, node)
        predicate = visit(node.predicate)
        statements = visit(node.statements)
        keyword = r(node.keyword_loc)

        if node.location.start_offset == node.keyword_loc.start_offset
          do_keyword =
            if node.do_keyword_loc
              r(node.do_keyword_loc)
            else
              semicolon(node.predicate.location.end_offset,
                        (node.statements&.location || node.closing_loc).start_offset)
            end
          map = keyword_map(keyword, do_keyword, EMPTY, r(node.closing_loc))
        else
          type = :"#{type}_post" if statements.kwbegin_type?
          map = Keyword.new(keyword, nil, nil, join(statements, predicate))
        end
        n(type, [check_condition(predicate), statements], map)
      end

      # --- parameters --------------------------------------------------------

      def visit_positional_parameter(param)
        return visit(param) if param.is_a?(::Prism::RequiredParameterNode)

        previous = @in_destructure
        @in_destructure = true
        begin
          visit(param)
        ensure
          @in_destructure = previous
        end
      end

      # The anonymous parameters that a method body is allowed to forward.
      def find_forwarding(parameters)
        return EMPTY if parameters.nil?

        forwarding = []
        rest = parameters.rest
        keyword_rest = parameters.keyword_rest
        forwarding << :* if rest.is_a?(::Prism::RestParameterNode) && rest.name.nil?
        forwarding << :** if keyword_rest.is_a?(::Prism::KeywordRestParameterNode) &&
                             keyword_rest.name.nil?
        block = parameters.block
        forwarding << :& if block.is_a?(::Prism::BlockParameterNode) && block.name.nil?
        forwarding |= %i[& ...] if keyword_rest.is_a?(::Prism::ForwardingParameterNode)
        forwarding
      end

      def multi_target_elements(node)
        elements = [*node.lefts]
        rest = node.rest
        elements << rest if rest && !rest.is_a?(::Prism::ImplicitRestNode)
        elements.concat(node.rights)
      end

      def with_forwarding(forwarding)
        previous = @forwarding
        @forwarding = forwarding
        yield
      ensure
        @forwarding = previous
      end

      def with_pattern(in_pattern)
        previous = @in_pattern
        @in_pattern = in_pattern
        yield
      ensure
        @in_pattern = previous
      end

      def within_pattern(&block)
        with_pattern(true, &block)
      end

      # --- pattern matching --------------------------------------------------

      def guard_node(type, keyword, body)
        n(type, [body], Keyword.new(keyword, nil, nil, keyword.join(body.loc.expression)))
      end

      def match_rest(operator, name_location)
        return n(:match_rest, EMPTY, unary_op_map(operator, nil)) unless name_location

        name = n(:match_var, [name_location.slice.to_sym], Variable.new(r(name_location)))
        n(:match_rest, [name], unary_op_map(operator, name))
      end

      # `tail` is the range up to the trailing comma of `in a,`.
      def array_pattern(begin_l, elements, end_l, tail)
        type = tail ? :array_pattern_with_tail : :array_pattern
        expression =
          if begin_l && end_l
            begin_l.join(end_l)
          elsif elements.any?
            elements.first.loc.expression.join(tail || elements.last.loc.expression)
          else
            begin_l || end_l
          end
        n(type, elements, Collection.new(begin_l, end_l, expression))
      end

      def const_pattern(const, begin_l, pattern, end_l)
        map = Collection.new(begin_l, end_l, const.loc.expression.join(end_l))
        n(:const_pattern, [const, pattern], map)
      end

      # --- hashes ------------------------------------------------------------

      # `{ foo: }` and the pattern `in { foo: }`.
      def implicit_assoc(key, value)
        if @in_pattern
          return match_hash_var(key) if key.is_a?(::Prism::SymbolNode) && key.opening.nil?

          parts =
            if key.is_a?(::Prism::SymbolNode)
              [str_internal(key.unescaped, r(key.value_loc))]
            else
              visit_all(key.parts)
            end
          return match_hash_var_from_str(r(key.opening_loc), parts, r(key.closing_loc))
        end

        value = value.value
        range = r(key.value_loc)
        implicit =
          case value
          when ::Prism::CallNode
            selector = r(value.message_loc)
            n(:send, [nil, value.name], Send.new(nil, selector, nil, nil, selector))
          when ::Prism::ConstantReadNode
            n(:const, [nil, value.name], Constant.new(nil, range, range))
          else
            n(:lvar, [value.name], Variable.new(range))
          end

        pair_keyword(key.unescaped, r(key.location), implicit)
      end

      def match_hash_var(key)
        expression = r(key.location)
        map = Variable.new(expression.adjust(end_pos: -1), expression)
        n(:match_var, [key.unescaped.to_sym], map)
      end

      def match_hash_var_from_str(begin_l, strings, end_l)
        string = strings.first
        return match_hash_var_from_str(begin_l, string.children, end_l) if string.begin_type?

        name, = *string
        name_l = string.loc.expression
        name_l = name_l.adjust(begin_pos: string.loc.begin.length) if string.loc.begin
        name_l = name_l.adjust(end_pos: -string.loc.end.length) if string.loc.end
        expression = begin_l.join(string.loc.expression).join(end_l)
        n(:match_var, [name.to_sym], Variable.new(name_l, expression))
      end

      def pair_keyword(name, key_range, value)
        key_l = key_range.adjust(end_pos: -1)
        colon = key_range.with(begin_pos: key_range.end_pos - 1)
        key = n(:sym, [name.to_sym], Collection.new(nil, nil, key_l))
        n(:pair, [key, value], Operator.new(colon, key_range.join(value.loc.expression)))
      end

      # The parts of the key in `{ "foo": 1 }`, one for each of its lines.
      def quoted_key_parts(key)
        content = key.value
        location = key.value_loc
        if content.empty?
          EMPTY
        elsif content.include?("\n")
          string_nodes_from_line_continuations(key.unescaped, content, location.start_offset,
                                               key.opening)
        else
          [str_internal(key.unescaped, r(location))]
        end
      end

      def pair_quoted(begin_l, parts, end_l, value)
        quote = end_l.with(begin_pos: end_l.end_pos - 2, end_pos: end_l.end_pos - 1)
        colon = end_l.with(begin_pos: end_l.end_pos - 1)
        key = symbol_compose(begin_l, parts, quote)
        n(:pair, [key, value], Operator.new(colon, begin_l.join(value.loc.expression)))
      end

      # --- numbers -----------------------------------------------------------

      def numeric(type, node, value)
        range = r(node.location)
        slice = node.slice
        return n(type, [value], Operator.new(nil, range)) unless slice.start_with?('+', '-')

        operator = range.with(end_pos: range.begin_pos + 1)
        n(type, [value], Operator.new(operator, range))
      end

      # `-` on one line and the number on the next is a method call for Ruby,
      # but a negative literal in the `parser` AST.
      def numeric_negate(message_loc, receiver)
        location = message_loc.join(receiver.location)

        case receiver.type
        when :integer_node, :float_node
          receiver.copy(value: -receiver.value, location: location)
        when :rational_node
          receiver.copy(numerator: -receiver.numerator, location: location)
        when :imaginary_node
          receiver.copy(numeric: numeric_negate(message_loc, receiver.numeric),
                        location: location)
        end
      end

      # --- strings, symbols, regexps -----------------------------------------

      def str_internal(value, range)
        n(:str, [value], Collection.new(nil, nil, range))
      end

      def collapse_string_parts?(parts)
        parts.one? && %i[str dstr].include?(parts.first.type)
      end

      def string_compose(begin_l, parts, end_l, heredoc: false)
        if collapse_string_parts?(parts)
          return parts.first if begin_l.nil? && end_l.nil?

          n(:str, parts.first.children, string_map(begin_l, parts, end_l, heredoc: heredoc))
        else
          n(:dstr, parts, string_map(begin_l, parts, end_l, heredoc: heredoc))
        end
      end

      def symbol_compose(begin_l, parts, end_l)
        if collapse_string_parts?(parts)
          string = parts.first
          map = Collection.new(begin_l, end_l, begin_l.join(end_l))
          n(:sym, [string.children.first.to_sym], map)
        else
          n(:dsym, parts, collection_map(begin_l, parts, end_l))
        end
      end

      def visit_delimited_string_node(node, opening)
        opening_source = node.opening

        if opening_source == '?'
          range = r(node.location)
          map = Collection.new(range.with(end_pos: range.begin_pos + 1), nil, range)
          return n(:str, [node.unescaped], map)
        end

        closing = r(node.closing_loc)
        unescaped = node.unescaped
        if opening_source.start_with?('%') && unescaped.empty?
          return n(:dstr, [], collection_map(opening, EMPTY, closing))
        end

        content = node.content
        parts =
          if content.include?("\n")
            string_nodes_from_line_continuations(unescaped, content,
                                                 node.content_loc.start_offset, opening_source)
          else
            [str_internal(unescaped, r(node.content_loc))]
          end
        string_compose(opening, parts, closing)
      end

      def regexp(node, parts)
        closing = node.closing
        closing_start = node.closing_loc.start_offset
        opening = r(node.opening_loc)
        options_l = ro(closing_start + 1, node.closing_loc.end_offset)
        flags = closing[1..].each_char.sort.uniq.map(&:to_sym)
        options = n(:regopt, flags, Map.new(options_l))
        closing_l = ro(closing_start, closing_start + 1)
        check_regexp(parts, options, opening.join(closing_l))
        n(:regexp, parts << options, Collection.new(opening, closing_l, opening.join(options_l)))
      end

      def check_regexp(parts, options, range)
        return unless @diagnostics && parts.all?(&:str_type?)

        compile_regexp(parts, options)
      rescue RegexpError, Encoding::UndefinedConversionError => e
        diagnostic(:error, :invalid_regexp, { message: e.message }, range)
      end

      def percent_array_elements(node, opening)
        node.elements.flat_map do |element|
          if element.is_a?(::Prism::StringNode)
            if element.content.include?("\n")
              string_nodes_from_line_continuations(element.unescaped, element.content,
                                                   element.content_loc.start_offset, opening)
            else
              [str_internal(element.unescaped, r(element.content_loc))]
            end
          elsif element.is_a?(::Prism::InterpolatedStringNode)
            string_compose(r(element.opening_loc),
                           string_nodes_from_interpolation(element, opening),
                           r(element.closing_loc))
          else
            [visit(element)]
          end
        end
      end

      # Visit a heredoc that can be either a string or an xstring.
      def visit_heredoc(node)
        children = []
        indented = false
        opening = node.opening
        parts = node.parts

        # A dedenting heredoc that starts with an interpolation gets the
        # leading whitespace as a part of its own.
        if opening.start_with?('<<~') && parts.any? && !parts.first.is_a?(::Prism::StringNode)
          location = parts.first.location
          start = location.start_offset - location.start_line_slice.bytesize
          range = ro(start, location.end_offset)
          children << str_internal(@source.byteslice(start...location.end_offset), range)
          indented = true
        end

        parts.each do |part|
          pushing =
            if part.is_a?(::Prism::StringNode) && part.content.include?("\n")
              string_nodes_from_line_continuations(part.unescaped, part.content,
                                                   part.location.start_offset, opening)
            else
              [visit(part)]
            end

          pushing.each { |child| push_heredoc_child(children, child) }
        end

        closing = node.closing
        closing_loc = node.closing_loc
        closing_l = ro(closing_loc.start_offset,
                       closing_loc.end_offset - (closing[/\s+$/]&.length || 0))
        composed = yield children, closing_l

        composed = composed.updated(nil, children[1..]) if indented
        composed
      end

      def push_heredoc_child(children, child)
        return children << child unless child.str_type?
        return if child.children.last == ''

        last = children.last
        return children << child unless last&.str_type? && !last.children.first.end_with?("\n")

        location = last.loc.with_expression(join(last, child))
        children[-1] = last.updated(:str, ["#{last.children.first}#{child.children.first}"],
                                    location: location)
      end

      # The `parser` gem creates a string node for each line of a string whose
      # content spans several lines.
      def string_nodes_from_interpolation(node, opening)
        node.parts.flat_map do |part|
          if part.type == :string_node && part.opening_loc.nil? && part.content.include?("\n")
            string_nodes_from_line_continuations(part.unescaped, part.content,
                                                 part.content_loc.start_offset, opening)
          else
            visit(part)
          end
        end
      end

      # Splits the content of a single prism string node into the string nodes
      # the `parser` gem has for it, which "glues" lines together when a line
      # continuation is encountered.
      def string_nodes_from_line_continuations(unescaped, escaped, start_offset, opening)
        unescaped = unescaped.lines
        escaped = escaped.lines
        percent_array = opening&.start_with?(*PERCENT_ARRAY)

        if opening&.end_with?("'") || opening&.start_with?('%q', '%s', '%w', '%i')
          return non_interpolating_lines(unescaped, escaped, start_offset, percent_array)
        end

        regex = opening == '/' || opening&.start_with?('%r')
        escaped_lengths = []
        normalized_lengths = []
        # Tracks where an unescaped line starts a new node. An unescaped `\n`
        # is otherwise indistinguishable from the newline that ends the line.
        do_next_tokens = []

        chunks = escaped.chunk_while do |before, _after|
          before[/(\\*)\r?\n$/, 1]&.length&.odd? || false
        end
        chunks.each do |lines|
          escaped_lengths << lines.sum(&:bytesize)

          unescaped_lines_count =
            if regex
              0
            else
              lines.sum do |line|
                count = line.scan(/(\\*)n/).count { |(backslashes)| backslashes&.length&.odd? }
                count -= 1 if line.match?(/(?:\A|[^\\])(?:\\\\)*\\n\z/) && count.positive?
                count
              end
            end

          extra = percent_array ? lines.count : 1
          normalized_lengths.concat(Array.new(unescaped_lines_count + extra, 0))
          normalized_lengths[-1] = lines.sum(&:bytesize)
          do_next_tokens.concat(Array.new(unescaped_lines_count + extra, false))
          do_next_tokens[-1] = true
        end

        current_line = +''
        current_normalized_length = 0
        emitted_count = 0

        unescaped.filter_map.with_index do |unescaped_line, index|
          current_line << unescaped_line
          current_normalized_length += normalized_lengths.fetch(index, 0)
          next unless do_next_tokens[index]

          part = str_internal(current_line,
                              ro(start_offset, start_offset + current_normalized_length))
          start_offset += escaped_lengths.fetch(emitted_count, 0)
          current_line = +''
          current_normalized_length = 0
          emitted_count += 1
          part
        end
      end

      def non_interpolating_lines(unescaped, escaped, start_offset, percent_array)
        current_length = 0
        current_line = +''

        escaped.filter_map.with_index do |escaped_line, index|
          current_length += escaped_line.bytesize
          current_line << unescaped.fetch(index, '')

          # Only %w and %i arrays can contain line continuations.
          if percent_array && escaped_line[/(\\)*\n$/, 1]&.length&.odd? &&
             index != escaped.count - 1
            next
          end

          part = str_internal(current_line, ro(start_offset, start_offset + current_length))
          start_offset += escaped_line.bytesize
          current_line = +''
          current_length = 0
          part
        end
      end
    end
    # rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    # rubocop:enable Metrics/ParameterLists
    # rubocop:enable InternalAffairs/NodeFirstOrLastArgument
  end
end
