# frozen_string_literal: true

module RuboCop
  module AST
    # `RuboCop::AST::Node` is a subclass of `Parser::AST::Node`. It provides
    # access to parent nodes and an object-oriented way to traverse an AST with
    # the power of `Enumerable`.
    #
    # It has predicate methods for every node type, like this:
    #
    # @example
    #   node.send_type?    # Equivalent to: `node.type == :send`
    #   node.op_asgn_type? # Equivalent to: `node.type == :op_asgn`
    #
    #   # Non-word characters (other than a-zA-Z0-9_) in type names are omitted.
    #   node.defined_type? # Equivalent to: `node.type == :defined?`
    #
    #   # Find the first lvar node under the receiver node.
    #   lvar_node = node.each_descendant.find(&:lvar_type?)
    #
    class Node < Parser::AST::Node # rubocop:disable Metrics/ClassLength
      include RuboCop::AST::Sexp
      extend NodePattern::Macros
      include RuboCop::AST::Descendence

      # @api private
      # <=> isn't included here, because it doesn't return a boolean.
      COMPARISON_OPERATORS = %i[== === != <= >= > <].to_set.freeze

      # @api private
      TRUTHY_LITERALS = %i[str dstr xstr int float sym dsym array
                           hash regexp true irange erange complex
                           rational regopt].to_set.freeze
      # @api private
      FALSEY_LITERALS = %i[false nil].to_set.freeze
      # @api private
      LITERALS = (TRUTHY_LITERALS + FALSEY_LITERALS).freeze
      # @api private
      COMPOSITE_LITERALS = %i[dstr xstr dsym array hash irange
                              erange regexp].to_set.freeze
      # @api private
      BASIC_LITERALS = (LITERALS - COMPOSITE_LITERALS).freeze
      # @api private
      MUTABLE_LITERALS = %i[str dstr xstr array hash
                            regexp irange erange].to_set.freeze
      # @api private
      IMMUTABLE_LITERALS = (LITERALS - MUTABLE_LITERALS).freeze

      # @api private
      EQUALS_ASSIGNMENTS = %i[lvasgn ivasgn cvasgn gvasgn
                              casgn masgn].to_set.freeze
      # @api private
      SHORTHAND_ASSIGNMENTS = %i[op_asgn or_asgn and_asgn].to_set.freeze
      # @api private
      ASSIGNMENTS = (EQUALS_ASSIGNMENTS + SHORTHAND_ASSIGNMENTS).freeze

      # @api private
      BASIC_CONDITIONALS = %i[if while until].to_set.freeze
      # @api private
      CONDITIONALS = (BASIC_CONDITIONALS + %i[case case_match]).freeze
      # @api private
      POST_CONDITION_LOOP_TYPES = %i[while_post until_post].to_set.freeze
      # @api private
      LOOP_TYPES = (POST_CONDITION_LOOP_TYPES + %i[while until for]).freeze
      # @api private
      VARIABLES = %i[ivar gvar cvar lvar].to_set.freeze
      # @api private
      REFERENCES = %i[nth_ref back_ref].to_set.freeze
      # @api private
      KEYWORDS = %i[alias and break case class def defs defined?
                    kwbegin do else ensure for if module next
                    not or postexe redo rescue retry return self
                    super zsuper then undef until when while
                    yield].to_set.freeze
      # @api private
      OPERATOR_KEYWORDS = %i[and or].to_set.freeze
      # @api private
      SPECIAL_KEYWORDS = %w[__FILE__ __LINE__ __ENCODING__].to_set.freeze
      # @api private
      ARGUMENT_TYPES = %i[arg optarg restarg kwarg kwoptarg kwrestarg
                          blockarg forward_arg shadowarg].to_set.freeze

      LITERAL_RECURSIVE_METHODS = (COMPARISON_OPERATORS + %i[* ! <=>]).freeze
      LITERAL_RECURSIVE_TYPES = (OPERATOR_KEYWORDS + COMPOSITE_LITERALS + %i[begin pair]).freeze
      private_constant :LITERAL_RECURSIVE_METHODS, :LITERAL_RECURSIVE_TYPES

      EMPTY_CHILDREN = [].freeze
      EMPTY_PROPERTIES = {}.freeze
      private_constant :EMPTY_CHILDREN, :EMPTY_PROPERTIES

      # @api private
      GROUP_FOR_TYPE = {
        arg: :argument,
        optarg: :argument,
        restarg: :argument,
        kwarg: :argument,
        kwoptarg: :argument,
        kwrestarg: :argument,
        blockarg: :argument,
        forward_arg: :argument,
        shardowarg: :argument,

        true: :boolean,
        false: :boolean,

        int: :numeric,
        float: :numeric,
        rational: :numeric,
        complex: :numeric,

        irange: :range,
        erange: :range,

        send: :call,
        csend: :call
      }.freeze
      private_constant :GROUP_FOR_TYPE

      # Define a +recursive_?+ predicate method for the given node kind.
      private_class_method def self.def_recursive_literal_predicate(kind) # rubocop:disable Metrics/MethodLength
        recursive_kind = "recursive_#{kind}?"
        kind_filter = "#{kind}?"

        class_eval <<~RUBY, __FILE__, __LINE__ + 1
          def #{recursive_kind}                                     # def recursive_literal?
            case type                                               #   case type
            when :send                                              #   when :send
              LITERAL_RECURSIVE_METHODS.include?(method_name) &&    #     LITERAL_RECURSIVE_METHODS.include?(method_name) &&
                receiver.send(:#{recursive_kind}) &&                #       receiver.send(:recursive_literal?) &&
                arguments.all?(&:#{recursive_kind})                 #       arguments.all?(&:recursive_literal?)
            when LITERAL_RECURSIVE_TYPES                            #   when LITERAL_RECURSIVE_TYPES
              children.compact.all?(&:#{recursive_kind})            #     children.compact.all?(&:recursive_literal?)
            else                                                    #   else
              send(:#{kind_filter})                                 #     send(:literal?)
            end                                                     #   end
          end                                                       # end
        RUBY
      end

      # Define a +_type?+ predicate method for the given node type.
      private_class_method def self.def_node_type_predicate(name, type = name)
        @node_types_with_documented_predicate_method << type

        class_eval <<~RUBY, __FILE__, __LINE__ + 1
          def #{name}_type?      # def block_type?
            @type == :#{type}    #   @type == :block
          end                    # end
        RUBY
      end
      @node_types_with_documented_predicate_method = []

      # @see https://www.rubydoc.info/gems/ast/AST/Node:initialize
      def initialize(type, children = EMPTY_CHILDREN, properties = EMPTY_PROPERTIES)
        @mutable_attributes = {}

        # ::AST::Node#initialize freezes itself.
        super

        # #parent= may be invoked multiple times for a node because there are
        # pending nodes while constructing AST and they are replaced later.
        # For example, `lvar` and `send` type nodes are initially created as an
        # `ident` type node and fixed to the appropriate type later.
        # So, the #parent attribute needs to be mutable.
        each_child_node do |child_node|
          child_node.parent = self unless child_node.complete?
        end
      end

      # Determine if the node is one of several node types in a single query
      # Allows specific single node types, as well as "grouped" types
      # (e.g. `:boolean` for `:true` or `:false`)
      def type?(*types)
        return true if types.include?(type)

        group_type = GROUP_FOR_TYPE[type]
        !group_type.nil? && types.include?(group_type)
      end

      # @!group Type Predicates

      # @!macro [attach] def_node_type_predicate
      #   @!method $1_type?
      #     @return [Boolean]
      def_node_type_predicate :true
      def_node_type_predicate :false
      def_node_type_predicate :nil
      def_node_type_predicate :int
      def_node_type_predicate :float
      def_node_type_predicate :str
      def_node_type_predicate :dstr
      def_node_type_predicate :sym
      def_node_type_predicate :dsym
      def_node_type_predicate :xstr
      def_node_type_predicate :regopt
      def_node_type_predicate :regexp
      def_node_type_predicate :array
      def_node_type_predicate :splat
      def_node_type_predicate :pair
      def_node_type_predicate :kwsplat
      def_node_type_predicate :hash
      def_node_type_predicate :irange
      def_node_type_predicate :erange
      def_node_type_predicate :self
      def_node_type_predicate :lvar
      def_node_type_predicate :ivar
      def_node_type_predicate :cvar
      def_node_type_predicate :gvar
      def_node_type_predicate :const
      def_node_type_predicate :defined, :defined?
      def_node_type_predicate :lvasgn
      def_node_type_predicate :ivasgn
      def_node_type_predicate :cvasgn
      def_node_type_predicate :gvasgn
      def_node_type_predicate :casgn
      def_node_type_predicate :mlhs
      def_node_type_predicate :masgn
      def_node_type_predicate :op_asgn
      def_node_type_predicate :and_asgn
      def_node_type_predicate :ensure
      def_node_type_predicate :rescue
      def_node_type_predicate :arg_expr
      def_node_type_predicate :or_asgn
      def_node_type_predicate :back_ref
      def_node_type_predicate :nth_ref
      def_node_type_predicate :match_with_lvasgn
      def_node_type_predicate :match_current_line
      def_node_type_predicate :module
      def_node_type_predicate :class
      def_node_type_predicate :sclass
      def_node_type_predicate :def
      def_node_type_predicate :defs
      def_node_type_predicate :undef
      def_node_type_predicate :alias
      def_node_type_predicate :args
      def_node_type_predicate :cbase
      def_node_type_predicate :arg
      def_node_type_predicate :optarg
      def_node_type_predicate :restarg
      def_node_type_predicate :blockarg
      def_node_type_predicate :block_pass
      def_node_type_predicate :kwarg
      def_node_type_predicate :kwoptarg
      def_node_type_predicate :kwrestarg
      def_node_type_predicate :kwnilarg
      def_node_type_predicate :csend
      def_node_type_predicate :super
      def_node_type_predicate :zsuper
      def_node_type_predicate :yield
      def_node_type_predicate :block
      def_node_type_predicate :and
      def_node_type_predicate :not
      def_node_type_predicate :or
      def_node_type_predicate :if
      def_node_type_predicate :when
      def_node_type_predicate :case
      def_node_type_predicate :while
      def_node_type_predicate :until
      def_node_type_predicate :while_post
      def_node_type_predicate :until_post
      def_node_type_predicate :for
      def_node_type_predicate :break
      def_node_type_predicate :next
      def_node_type_predicate :redo
      def_node_type_predicate :return
      def_node_type_predicate :resbody
      def_node_type_predicate :kwbegin
      def_node_type_predicate :begin
      def_node_type_predicate :retry
      def_node_type_predicate :preexe
      def_node_type_predicate :postexe
      def_node_type_predicate :iflipflop
      def_node_type_predicate :eflipflop
      def_node_type_predicate :shadowarg
      def_node_type_predicate :complex
      def_node_type_predicate :rational
      def_node_type_predicate :__FILE__
      def_node_type_predicate :__LINE__
      def_node_type_predicate :__ENCODING__
      def_node_type_predicate :ident
      def_node_type_predicate :lambda
      def_node_type_predicate :indexasgn
      def_node_type_predicate :index
      def_node_type_predicate :procarg0
      def_node_type_predicate :restarg_expr
      def_node_type_predicate :blockarg_expr
      def_node_type_predicate :objc_kwarg
      def_node_type_predicate :objc_restarg
      def_node_type_predicate :objc_varargs
      def_node_type_predicate :numargs
      def_node_type_predicate :numblock
      def_node_type_predicate :forward_args
      def_node_type_predicate :forwarded_args
      def_node_type_predicate :forward_arg
      def_node_type_predicate :case_match
      def_node_type_predicate :in_match
      def_node_type_predicate :in_pattern
      def_node_type_predicate :match_var
      def_node_type_predicate :pin
      def_node_type_predicate :match_alt
      def_node_type_predicate :match_as
      def_node_type_predicate :match_rest
      def_node_type_predicate :array_pattern
      def_node_type_predicate :match_with_trailing_comma
      def_node_type_predicate :array_pattern_with_tail
      def_node_type_predicate :hash_pattern
      def_node_type_predicate :const_pattern
      def_node_type_predicate :if_guard
      def_node_type_predicate :unless_guard
      def_node_type_predicate :match_nil_pattern
      def_node_type_predicate :empty_else
      def_node_type_predicate :find_pattern
      def_node_type_predicate :kwargs
      def_node_type_predicate :match_pattern_p
      def_node_type_predicate :match_pattern
      def_node_type_predicate :forwarded_restarg
      def_node_type_predicate :forwarded_kwrestarg

      def send_type?
        # Most nodes are of 'send' type, so this method is defined
        # separately to make this check as fast as possible.
        false
      end
      @node_types_with_documented_predicate_method << :send

      # Ensure forward compatibility with new node types by defining methods for unknown node types.
      # Note these won't get auto-generated documentation, which is why we prefer defining them above.
      (Parser::Meta::NODE_TYPES - @node_types_with_documented_predicate_method).each do |node_type|
        method_name = :"#{node_type.to_s.gsub(/\W/, '')}_type?"
        define_method(method_name) { false }
      end

      # @!endgroup

      # Returns the parent node, or `nil` if the receiver is a root node.
      #
      # @return [Node, nil] the parent node or `nil`
      def parent
        @mutable_attributes[:parent]
      end

      def parent=(node)
        @mutable_attributes[:parent] = node
      end

      # @return [Boolean]
      def parent?
        !!parent
      end

      # @return [Boolean]
      def root?
        !parent
      end

      def complete!
        @mutable_attributes.freeze
        each_child_node(&:complete!)
      end

      def complete?
        @mutable_attributes.frozen?
      end

      protected :parent=

      # Override `AST::Node#updated` so that `AST::Processor` does not try to
      # mutate our ASTs. Since we keep references from children to parents and
      # not just the other way around, we cannot update an AST and share
      # identical subtrees. Rather, the entire AST must be copied any time any
      # part of it is changed.
      def updated(type = nil, children = nil, properties = {})
        properties[:location] ||= @location
        klass = RuboCop::AST::Builder::NODE_MAP[type || @type] || Node
        klass.new(type || @type, children || @children, properties)
      end

      # Returns the index of the receiver node in its siblings. (Sibling index
      # uses zero based numbering.)
      # Use is discouraged, this is a potentially slow method.
      #
      # @return [Integer, nil] the index of the receiver node in its siblings
      def sibling_index
        parent&.children&.index { |sibling| sibling.equal?(self) }
      end

      # Use is discouraged, this is a potentially slow method and can lead
      # to even slower algorithms
      # @return [Node, nil] the right (aka next) sibling
      def right_sibling
        return unless parent

        parent.children[sibling_index + 1].freeze
      end

      # Use is discouraged, this is a potentially slow method and can lead
      # to even slower algorithms
      # @return [Node, nil] the left (aka previous) sibling
      def left_sibling
        i = sibling_index
        return if i.nil? || i.zero?

        parent.children[i - 1].freeze
      end

      # Use is discouraged, this is a potentially slow method and can lead
      # to even slower algorithms
      # @return [Array<Node>] the left (aka previous) siblings
      def left_siblings
        return [].freeze unless parent

        parent.children[0...sibling_index].freeze
      end

      # Use is discouraged, this is a potentially slow method and can lead
      # to even slower algorithms
      # @return [Array<Node>] the right (aka next) siblings
      def right_siblings
        return [].freeze unless parent

        parent.children[sibling_index + 1..].freeze
      end

      # Common destructuring method. This can be used to normalize
      # destructuring for different variations of the node.
      # Some node types override this with their own custom
      # destructuring method.
      #
      # @return [Array<Node>] the different parts of the ndde
      alias node_parts to_a

      # Calls the given block for each ancestor node from parent to root.
      # If no block is given, an `Enumerator` is returned.
      #
      # @overload each_ancestor
      #   Yield all nodes.
      # @overload each_ancestor(type)
      #   Yield only nodes matching the type.
      #   @param [Symbol] type a node type
      # @overload each_ancestor(type_a, type_b, ...)
      #   Yield only nodes matching any of the types.
      #   @param [Symbol] type_a a node type
      #   @param [Symbol] type_b a node type
      # @yieldparam [Node] node each ancestor node
      # @return [self] if a block is given
      # @return [Enumerator] if no block is given
      def each_ancestor(*types, &block)
        return to_enum(__method__, *types) unless block

        visit_ancestors(types, &block)

        self
      end

      # Returns an array of ancestor nodes.
      # This is a shorthand for `node.each_ancestor.to_a`.
      #
      # @return [Array<Node>] an array of ancestor nodes
      def ancestors
        each_ancestor.to_a
      end

      # NOTE: Some rare nodes may have no source, like `s(:args)` in `foo {}`
      # @return [String, nil]
      def source
        loc.expression&.source
      end

      def source_range
        loc.expression
      end

      def first_line
        loc.line
      end

      def last_line
        loc.last_line
      end

      def line_count
        return 0 unless source_range

        source_range.last_line - source_range.first_line + 1
      end

      def nonempty_line_count
        source.lines.grep(/\S/).size
      end

      def source_length
        source_range ? source_range.size : 0
      end

      ## Destructuring

      # @!method receiver(node = self)
      def_node_matcher :receiver, <<~PATTERN
        {(send $_ ...) ({block numblock} (call $_ ...) ...)}
      PATTERN

      # @!method str_content(node = self)
      def_node_matcher :str_content, '(str $_)'

      def const_name
        return unless const_type? || casgn_type?

        if namespace && !namespace.cbase_type?
          "#{namespace.const_name}::#{short_name}"
        else
          short_name.to_s
        end
      end

      # @!method defined_module0(node = self)
      def_node_matcher :defined_module0, <<~PATTERN
        {(class (const $_ $_) ...)
         (module (const $_ $_) ...)
         (casgn $_ $_        (send #global_const?({:Class :Module}) :new ...))
         (casgn $_ $_ (block (send #global_const?({:Class :Module}) :new ...) ...))}
      PATTERN

      private :defined_module0

      def defined_module
        namespace, name = *defined_module0
        s(:const, namespace, name) if name
      end

      def defined_module_name
        (const = defined_module) && const.const_name
      end

      ## Searching the AST

      def parent_module_name
        # what class or module is this method/constant/etc definition in?
        # returns nil if answer cannot be determined
        ancestors = each_ancestor(:class, :module, :sclass, :casgn, :block)
        result    = ancestors.filter_map do |ancestor|
          parent_module_name_part(ancestor) do |full_name|
            return nil unless full_name

            full_name
          end
        end.reverse.join('::')
        result.empty? ? 'Object' : result
      end

      ## Predicates

      def multiline?
        line_count > 1
      end

      def single_line?
        line_count == 1
      end

      def empty_source?
        source_length.zero?
      end

      # Some cops treat the shovel operator as a kind of assignment.
      # @!method assignment_or_similar?(node = self)
      def_node_matcher :assignment_or_similar?, <<~PATTERN
        {assignment? (send _recv :<< ...)}
      PATTERN

      def literal?
        LITERALS.include?(type)
      end

      def basic_literal?
        BASIC_LITERALS.include?(type)
      end

      def truthy_literal?
        TRUTHY_LITERALS.include?(type)
      end

      def falsey_literal?
        FALSEY_LITERALS.include?(type)
      end

      def mutable_literal?
        MUTABLE_LITERALS.include?(type)
      end

      def immutable_literal?
        IMMUTABLE_LITERALS.include?(type)
      end

      # @!macro [attach] def_recursive_literal_predicate
      #   @!method recursive_$1?
      #     @return [Boolean]
      def_recursive_literal_predicate :literal
      def_recursive_literal_predicate :basic_literal

      def variable?
        VARIABLES.include?(type)
      end

      def reference?
        REFERENCES.include?(type)
      end

      def equals_asgn?
        EQUALS_ASSIGNMENTS.include?(type)
      end

      def shorthand_asgn?
        SHORTHAND_ASSIGNMENTS.include?(type)
      end

      def assignment?
        ASSIGNMENTS.include?(type)
      end

      def basic_conditional?
        BASIC_CONDITIONALS.include?(type)
      end

      def conditional?
        CONDITIONALS.include?(type)
      end

      def post_condition_loop?
        POST_CONDITION_LOOP_TYPES.include?(type)
      end

      # NOTE: `loop { }` is a normal method call and thus not a loop keyword.
      def loop_keyword?
        LOOP_TYPES.include?(type)
      end

      def keyword?
        return true if special_keyword? || (send_type? && prefix_not?)
        return false unless KEYWORDS.include?(type)

        !OPERATOR_KEYWORDS.include?(type) || loc.operator.is?(type.to_s)
      end

      def special_keyword?
        SPECIAL_KEYWORDS.include?(source)
      end

      def operator_keyword?
        OPERATOR_KEYWORDS.include?(type)
      end

      def parenthesized_call?
        loc.respond_to?(:begin) && loc.begin&.is?('(')
      end

      def call_type?
        GROUP_FOR_TYPE[type] == :call
      end

      def chained?
        parent&.call_type? && eql?(parent.receiver)
      end

      def argument?
        parent&.send_type? && parent.arguments.include?(self)
      end

      def argument_type?
        GROUP_FOR_TYPE[type] == :argument
      end

      def boolean_type?
        GROUP_FOR_TYPE[type] == :boolean
      end

      def numeric_type?
        GROUP_FOR_TYPE[type] == :numeric
      end

      def range_type?
        GROUP_FOR_TYPE[type] == :range
      end

      def guard_clause?
        node = operator_keyword? ? rhs : self

        node.match_guard_clause?
      end

      # @!method match_guard_clause?(node = self)
      def_node_matcher :match_guard_clause?, <<~PATTERN
        [${(send nil? {:raise :fail} ...) return break next} single_line?]
      PATTERN

      # @!method proc?(node = self)
      def_node_matcher :proc?, <<~PATTERN
        {(block (send nil? :proc) ...)
         (block (send #global_const?(:Proc) :new) ...)
         (send #global_const?(:Proc) :new)}
      PATTERN

      # @!method lambda?(node = self)
      def_node_matcher :lambda?, '({block numblock} (send nil? :lambda) ...)'

      # @!method lambda_or_proc?(node = self)
      def_node_matcher :lambda_or_proc?, '{lambda? proc?}'

      # @!method global_const?(node = self, name)
      def_node_matcher :global_const?, '(const {nil? cbase} %1)'

      # @!method class_constructor?(node = self)
      def_node_matcher :class_constructor?, <<~PATTERN
        {
          (send #global_const?({:Class :Module :Struct}) :new ...)
          (send #global_const?(:Data) :define ...)
          ({block numblock} {
            (send #global_const?({:Class :Module :Struct}) :new ...)
            (send #global_const?(:Data) :define ...)
          } ...)
        }
      PATTERN

      # @deprecated Use `:class_constructor?`
      # @!method struct_constructor?(node = self)
      def_node_matcher :struct_constructor?, <<~PATTERN
        ({block numblock} (send #global_const?(:Struct) :new ...) _ $_)
      PATTERN

      # @!method class_definition?(node = self)
      def_node_matcher :class_definition?, <<~PATTERN
        {(class _ _ $_)
         (sclass _ $_)
         ({block numblock} (send #global_const?({:Struct :Class}) :new ...) _ $_)}
      PATTERN

      # @!method module_definition?(node = self)
      def_node_matcher :module_definition?, <<~PATTERN
        {(module _ $_)
         ({block numblock} (send #global_const?(:Module) :new ...) _ $_)}
      PATTERN

      # Some expressions are evaluated for their value, some for their side
      # effects, and some for both
      # If we know that an expression is useful only for its side effects, that
      # means we can transform it in ways which preserve the side effects, but
      # change the return value
      # So, does the return value of this node matter? If we changed it to
      # `(...; nil)`, might that affect anything?
      #
      def value_used? # rubocop:disable Metrics/MethodLength
        # Be conservative and return true if we're not sure.
        return false if parent.nil?

        case parent.type
        when :array, :defined?, :dstr, :dsym, :eflipflop, :erange, :float,
             :hash, :iflipflop, :irange, :not, :pair, :regexp, :str, :sym,
             :when, :xstr
          parent.value_used?
        when :begin, :kwbegin
          begin_value_used?
        when :for
          for_value_used?
        when :case, :if
          case_if_value_used?
        when :while, :until, :while_post, :until_post
          while_until_value_used?
        else
          true
        end
      end

      # Some expressions are evaluated for their value, some for their side
      # effects, and some for both.
      # If we know that expressions are useful only for their return values,
      # and have no side effects, that means we can reorder them, change the
      # number of times they are evaluated, or replace them with other
      # expressions which are equivalent in value.
      # So, is evaluation of this node free of side effects?
      #
      def pure?
        # Be conservative and return false if we're not sure
        case type
        when :__FILE__, :__LINE__, :const, :cvar, :defined?, :false, :float,
             :gvar, :int, :ivar, :lvar, :nil, :str, :sym, :true, :regopt
          true
        when :and, :array, :begin, :case, :dstr, :dsym, :eflipflop, :ensure,
             :erange, :for, :hash, :if, :iflipflop, :irange, :kwbegin, :not,
             :or, :pair, :regexp, :until, :until_post, :when, :while,
             :while_post
          child_nodes.all?(&:pure?)
        else
          false
        end
      end

      private

      def visit_ancestors(types)
        last_node = self

        while (current_node = last_node.parent)
          yield current_node if types.empty? ||
                                types.include?(current_node.type)
          last_node = current_node
        end
      end

      def begin_value_used?
        # the last child node determines the value of the parent
        sibling_index == parent.children.size - 1 ? parent.value_used? : false
      end

      def for_value_used?
        # `for var in enum; body; end`
        # (for <var> <enum> <body>)
        sibling_index == 2 ? parent.value_used? : true
      end

      def case_if_value_used?
        # (case <condition> <when...>)
        # (if <condition> <truebranch> <falsebranch>)
        sibling_index.zero? ? true : parent.value_used?
      end

      def while_until_value_used?
        # (while <condition> <body>) -> always evaluates to `nil`
        sibling_index.zero?
      end

      def parent_module_name_part(node)
        case node.type
        when :class, :module, :casgn
          # TODO: if constant name has cbase (leading ::), then we don't need
          # to keep traversing up through nested classes/modules
          node.defined_module_name
        when :sclass
          yield parent_module_name_for_sclass(node)
        else # block
          parent_module_name_for_block(node) { yield nil }
        end
      end

      def parent_module_name_for_sclass(sclass_node)
        # TODO: look for constant definition and see if it is nested
        # inside a class or module
        subject = sclass_node.children[0]

        if subject.const_type?
          "#<Class:#{subject.const_name}>"
        elsif subject.self_type?
          "#<Class:#{sclass_node.parent_module_name}>"
        end
      end

      def parent_module_name_for_block(ancestor)
        if ancestor.method?(:class_eval)
          # `class_eval` with no receiver applies to whatever module or class
          # we are currently in
          return unless (receiver = ancestor.receiver)

          yield unless receiver.const_type?
          receiver.const_name
        elsif !new_class_or_module_block?(ancestor)
          yield
        end
      end

      # @!method new_class_or_module_block?(node = self)
      def_node_matcher :new_class_or_module_block?, <<~PATTERN
        ^(casgn _ _ (block (send (const _ {:Class :Module}) :new) ...))
      PATTERN
    end
  end
end
