# frozen_string_literal: true

module RuboCop
  module AST
    # What the children of the nodes of one type are: how many there are, and
    # which of them are nodes and which are values like a symbol.
    #
    # A layout is described by one word per child:
    #
    # * `node` is a node, and the name of a class is a value of that class
    # * `node?` is a child that may be `nil`
    # * `[node]` is a child that may be missing
    # * `node*` is any number of children, and `node+` at least one
    #
    # So `send` nodes are `node? Symbol node*`: the receiver, if there is one,
    # the method name and the arguments.
    #
    # Only the node types that the parsers emit for the supported Ruby
    # versions have a layout.
    #
    # @api private
    class NodeLayout
      # One child, or a run of children, of the same kinds.
      Child = Struct.new(:kinds, :least, :most)

      DESCRIPTIONS = {
        # Literals
        true: '', false: '', nil: '',
        int: 'Integer', float: 'Float', rational: 'Rational', complex: 'Complex',
        str: 'String', sym: 'Symbol',
        dstr: 'node*', dsym: 'node*', xstr: 'node*',
        regexp: 'node+', regopt: 'Symbol*',
        array: 'node*', hash: 'node*', pair: 'node node',
        splat: '[node]', kwsplat: '[node]',
        irange: 'node? node?', erange: 'node? node?',

        # Variables and constants
        self: '', cbase: '',
        lvar: 'Symbol', ivar: 'Symbol', cvar: 'Symbol', gvar: 'Symbol',
        nth_ref: 'Integer', back_ref: 'Symbol',
        const: 'node? Symbol',

        # Assignments
        lvasgn: 'Symbol [node]', ivasgn: 'Symbol [node]',
        cvasgn: 'Symbol [node]', gvasgn: 'Symbol [node]',
        casgn: 'node? Symbol [node]',
        masgn: 'node node', mlhs: 'node+',
        op_asgn: 'node Symbol node', or_asgn: 'node node', and_asgn: 'node node',
        match_with_lvasgn: 'node node',

        # Definitions
        def: 'Symbol node node?', defs: 'node Symbol node node?',
        class: 'node node? node?', module: 'node node?', sclass: 'node node?',
        alias: 'node node', undef: 'node+',

        # Arguments
        args: 'node*',
        arg: 'Symbol', optarg: 'Symbol node', restarg: '[Symbol]',
        kwarg: 'Symbol', kwoptarg: 'Symbol node', kwrestarg: '[Symbol]', kwnilarg: '',
        blockarg: 'Symbol?', shadowarg: 'Symbol', forward_arg: '',
        forwarded_args: '', forwarded_restarg: '', forwarded_kwrestarg: '',

        # Calls
        send: 'node? Symbol node*', csend: 'node Symbol node*',
        super: 'node*', zsuper: '', yield: 'node*',
        block: 'node node node?', numblock: 'node Integer node?', itblock: 'node Symbol node?',
        block_pass: 'node?',

        # Control flow
        and: 'node node', or: 'node node', defined?: 'node',
        if: 'node node? node?',
        case: 'node? node+ node?', when: 'node+ node?',
        while: 'node node?', until: 'node node?',
        while_post: 'node node', until_post: 'node node',
        for: 'node node node?',
        iflipflop: 'node? node?', eflipflop: 'node? node?',
        match_current_line: 'node',
        return: 'node*', break: 'node*', next: 'node*', redo: '', retry: '',
        begin: 'node*', kwbegin: 'node*',
        rescue: 'node? node+ node?', resbody: 'node? node? node?', ensure: 'node? node?',
        preexe: 'node?', postexe: 'node?',

        # Pattern matching
        case_match: 'node node+ node?', in_pattern: 'node node? node?', empty_else: '',
        match_pattern: 'node node', match_pattern_p: 'node node',
        match_var: 'Symbol', match_rest: '[node]', match_nil_pattern: '',
        match_as: 'node node', match_alt: 'node node', pin: 'node',
        if_guard: 'node', unless_guard: 'node',
        array_pattern: 'node*', array_pattern_with_tail: 'node*', find_pattern: 'node+',
        hash_pattern: 'node*', const_pattern: 'node node'
      }.freeze

      WORD = /\A(?<optional>\[)?(?<kind>\w+)(?<nilable>\?)?\]?(?<repeated>[*+])?\z/.freeze
      private_constant :WORD

      class << self
        # @return [NodeLayout, nil] the layout of the nodes of the given type
        def of(type)
          LAYOUTS[type]
        end

        # @return [Symbol, Class] `:node`, or the class of a child that is a value
        def kind(child)
          child.is_a?(::AST::Node) ? :node : child.class
        end
      end

      # @return [Range] how many children a node can have
      attr_reader :arity

      def initialize(description)
        @children = description.split.map { |word| parse(word) }.freeze
        @arity = @children.sum(&:least)..@children.sum(&:most)
      end

      # @return [Array<Symbol, Class>] what the child at the index can be
      def kinds(index)
        least = most = 0
        @children.each_with_object([]) do |child, kinds|
          kinds.concat(child.kinds) if index >= least && index < most + child.most
          least += child.least
          most += child.most
        end.uniq
      end

      # @return [Boolean] whether a node can have these children
      def fit?(children, layout = @children)
        child, *rest = layout
        return children.empty? unless child

        [child.most, children.size].min.downto(child.least).any? do |count|
          children.first(count).all? { |value| child.kinds.include?(self.class.kind(value)) } &&
            fit?(children.drop(count), rest)
        end
      end

      private

      def parse(word)
        match = WORD.match(word) || raise(ArgumentError, "invalid layout: #{word}")
        kinds = [match[:kind] == 'node' ? :node : Object.const_get(match[:kind])]
        kinds << NilClass if match[:nilable]
        least = match[:optional] || match[:repeated] == '*' ? 0 : 1

        Child.new(kinds.freeze, least, match[:repeated] ? Float::INFINITY : 1).freeze
      end

      LAYOUTS = DESCRIPTIONS.transform_values { |description| new(description) }.freeze
      private_constant :LAYOUTS
    end
  end
end
