# frozen_string_literal: true

require 'uri'

RSpec.describe RuboCop::AST::Node do
  let(:ast) { parse_source(src).node }
  let(:node) { ast }

  describe '#value_used?' do
    before :all do
      module RuboCop # rubocop:disable Lint/ConstantDefinitionInBlock
        module AST
          # Patch Node
          class Node
            # Let's make our predicate matchers read better
            def used?
              value_used?
            end
          end
        end
      end
    end

    context 'at the top level' do
      let(:src) { 'expr' }

      it 'is false' do
        expect(node).not_to be_used
      end
    end

    context 'within a method call node' do
      let(:src) { 'obj.method(arg1, arg2, arg3)' }

      it 'is always true' do
        expect(node.child_nodes).to all(be_used)
      end
    end

    context 'at the end of a block' do
      let(:src) { 'obj.method { blah; expr }' }

      it 'is always true' do
        expect(node.children.last).to be_used
      end
    end

    context 'within a class definition node' do
      let(:src) { 'class C < Super; def a; 1; end; self; end' }

      it 'is always true' do
        expect(node.child_nodes).to all(be_used)
      end
    end

    context 'within a module definition node' do
      let(:src) { 'module M; def method; end; 1; end' }

      it 'is always true' do
        expect(node.child_nodes).to all(be_used)
      end
    end

    context 'within a singleton class node' do
      let(:src) { 'class << obj; 1; 2; end' }

      it 'is always true' do
        expect(node.child_nodes).to all(be_used)
      end
    end

    context 'within an if...else..end node' do
      context 'nested in a method call' do
        let(:src) { 'obj.method(if a then b else c end)' }

        it 'is always true' do
          if_node = node.children[2]
          expect(if_node.child_nodes).to all(be_used)
        end
      end

      context 'at the top level' do
        let(:src) { 'if a then b else c end' }

        it 'is true only for the condition' do
          expect(node.condition).to be_used
          expect(node.if_branch).not_to be_used
          expect(node.else_branch).not_to be_used
        end
      end
    end

    context 'within an array literal' do
      context 'assigned to an ivar' do
        let(:src) { '@var = [a, b, c]' }

        it 'is always true' do
          ary_node = node.children[1]
          expect(ary_node.child_nodes).to all(be_used)
        end
      end

      context 'at the top level' do
        let(:src) { '[a, b, c]' }

        it 'is always false' do
          expect(node.child_nodes.map(&:used?)).to all(be false)
        end
      end
    end

    context 'within a while node' do
      let(:src) { 'while a; b; end' }

      it 'is true only for the condition' do
        expect(node.condition).to be_used
        expect(node.body).not_to be_used
      end
    end
  end

  describe '#recursive_basic_literal?' do
    shared_examples 'literal' do |source|
      let(:src) { source }

      it "returns true for `#{source}`" do
        expect(node).to be_recursive_literal
      end
    end

    it_behaves_like 'literal', '!true'
    it_behaves_like 'literal', '"#{2}"'
    it_behaves_like 'literal', '(1)'
    it_behaves_like 'literal', '(false && true)'
    it_behaves_like 'literal', '(false <=> true)'
    it_behaves_like 'literal', '(false or true)'
    it_behaves_like 'literal', '[1, 2, 3]'
    it_behaves_like 'literal', '{ :a => 1, :b => 2 }'
    it_behaves_like 'literal', '{ a: 1, b: 2 }'
    it_behaves_like 'literal', '/./'
    it_behaves_like 'literal', '%r{abx}ixo'
    it_behaves_like 'literal', '1.0'
    it_behaves_like 'literal', '1'
    it_behaves_like 'literal', 'false'
    it_behaves_like 'literal', 'nil'
    it_behaves_like 'literal', "'str'"

    shared_examples 'non literal' do |source|
      let(:src) { source }

      it "returns false for `#{source}`" do
        expect(node).not_to be_recursive_literal
      end
    end

    it_behaves_like 'non literal', '(x && false)'
    it_behaves_like 'non literal', '(x == false)'
    it_behaves_like 'non literal', '(x or false)'
    it_behaves_like 'non literal', '[some_method_call]'
    it_behaves_like 'non literal', '{ :sym => some_method_call }'
    it_behaves_like 'non literal', '{ some_method_call => :sym }'
    it_behaves_like 'non literal', '/.#{some_method_call}/'
    it_behaves_like 'non literal', '%r{abx#{foo}}ixo'
    it_behaves_like 'non literal', 'some_method_call'
    it_behaves_like 'non literal', 'some_method_call(x, y)'
  end

  describe '#pure?' do
    context 'for a method call' do
      let(:src) { 'obj.method(arg1, arg2)' }

      it 'returns false' do
        expect(node).not_to be_pure
      end
    end

    context 'for an integer literal' do
      let(:src) { '100' }

      it 'returns true' do
        expect(node).to be_pure
      end
    end

    context 'for an array literal' do
      context 'with only literal children' do
        let(:src) { '[1..100, false, :symbol, "string", 1.0]' }

        it 'returns true' do
          expect(node).to be_pure
        end
      end

      context 'which contains a method call' do
        let(:src) { '[1, 2, 3, 3 + 4]' }

        it 'returns false' do
          expect(node).not_to be_pure
        end
      end
    end

    context 'for a hash literal' do
      context 'with only literal children' do
        let(:src) { '{range: 1..100, bool: false, str: "string", float: 1.0}' }

        it 'returns true' do
          expect(node).to be_pure
        end
      end

      context 'which contains a method call' do
        let(:src) { '{a: 1, b: 2, c: Kernel.exit}' }

        it 'returns false' do
          expect(node).not_to be_pure
        end
      end
    end

    context 'for a nested if' do
      context 'where the innermost descendants are local vars and literals' do
        let(:src) do
          ['lvar1, lvar2 = method1, method2',
           'if $global',
           '  if @initialized',
           '    [lvar1, lvar2, true]',
           '  else',
           '    :symbol',
           '  end',
           'else',
           '  lvar1',
           'end'].join("\n")
        end

        it 'returns true' do
          if_node = node.children[1]
          expect(if_node.type).to be :if
          expect(if_node).to be_pure
        end
      end

      context 'where one branch contains a method call' do
        let(:src) { 'if $DEBUG then puts "hello" else nil end' }

        it 'returns false' do
          expect(node).not_to be_pure
        end
      end

      context 'where one branch contains an assignment statement' do
        let(:src) { 'if @a then 1 else $global = "str" end' }

        it 'returns false' do
          expect(node).not_to be_pure
        end
      end
    end

    context 'for an ivar assignment' do
      let(:src) { '@var = 1' }

      it 'returns false' do
        expect(node).not_to be_pure
      end
    end

    context 'for a gvar assignment' do
      let(:src) { '$var = 1' }

      it 'returns false' do
        expect(node).not_to be_pure
      end
    end

    context 'for a cvar assignment' do
      let(:src) { '@@var = 1' }

      it 'returns false' do
        expect(node).not_to be_pure
      end
    end

    context 'for an lvar assignment' do
      let(:src) { 'var = 1' }

      it 'returns false' do
        expect(node).not_to be_pure
      end
    end

    context 'for a class definition' do
      let(:src) { 'class C < Super; def method; end end' }

      it 'returns false' do
        expect(node).not_to be_pure
      end
    end

    context 'for a module definition' do
      let(:src) { 'module M; def method; end end' }

      it 'returns false' do
        expect(node).not_to be_pure
      end
    end

    context 'for a regexp' do
      let(:opts) { '' }
      let(:body) { '' }
      let(:src) { "/#{body}/#{opts}" }

      context 'with interpolated segments' do
        let(:body) { '#{x}' }

        it 'returns false' do
          expect(node).not_to be_pure
        end
      end

      context 'with no interpolation' do
        let(:src) { URI::DEFAULT_PARSER.make_regexp.inspect }

        it 'returns true' do
          expect(node).to be_pure
        end
      end

      context 'with options' do
        let(:opts) { 'oix' }

        it 'returns true' do
          expect(node).to be_pure
        end
      end
    end
  end

  describe 'sibling_access' do
    let(:src) { '[0, 1, 2, 3, 4, 5]' }

    it 'returns trivial values for a root node' do
      expect(node.sibling_index).to be_nil
      expect(node.left_sibling).to be_nil
      expect(node.right_sibling).to be_nil
      expect(node.left_siblings).to eq []
      expect(node.right_siblings).to eq []
    end

    context 'for a node with siblings' do
      let(:node) { ast.children[2] }

      it 'returns the expected values' do
        expect(node.sibling_index).to eq 2
        expect(node.left_sibling.value).to eq 1
        expect(node.right_sibling.value).to eq 3
        expect(node.left_siblings.map(&:value)).to eq [0, 1]
        expect(node.right_siblings.map(&:value)).to eq [3, 4, 5]
      end
    end

    context 'for a single child' do
      let(:src) { '[0]' }
      let(:node) { ast.children[0] }

      it 'returns the expected values' do
        expect(node.sibling_index).to eq 0
        expect(node.left_sibling).to be_nil
        expect(node.right_sibling).to be_nil
        expect(node.left_siblings.map(&:value)).to eq []
        expect(node.right_siblings.map(&:value)).to eq []
      end
    end
  end

  describe '#argument_type?' do
    context 'block arguments' do
      let(:src) { 'bar { |a, b = 42, *c, d: 42, **e| nil }' }

      it 'returns true for all argument types' do
        expect(node.arguments.children).to all be_argument_type
        expect(node.arguments).not_to be_argument_type
      end
    end

    context 'method arguments' do
      let(:src) { 'def method_name(a = 0, *b, c: 42, **d); end' }

      it 'returns true for all argument types' do
        expect(node.arguments.children).to all be_argument_type
        expect(node.arguments).not_to be_argument_type
      end
    end
  end

  describe '#class_constructor?' do
    context 'class definition with a block' do
      let(:src) { 'Class.new { a = 42 }' }

      it 'matches' do
        expect(node).to be_class_constructor
      end
    end

    context 'module definition with a block' do
      let(:src) { 'Module.new { a = 42 }' }

      it 'matches' do
        expect(node).to be_class_constructor
      end
    end

    context 'class definition' do
      let(:src) { 'class Foo; a = 42; end' }

      it 'does not match' do
        expect(node.class_constructor?).to be_nil
      end
    end

    context 'class definition on outer scope' do
      let(:src) { '::Class.new { a = 42 }' }

      it 'matches' do
        expect(node).to be_class_constructor
      end
    end

    context 'using Ruby >= 2.7', :ruby27 do
      context 'class definition with a numblock' do
        let(:src) { 'Class.new { do_something(_1) }' }

        it 'matches' do
          expect(node).to be_class_constructor
        end
      end

      context 'module definition with a numblock' do
        let(:src) { 'Module.new { do_something(_1) }' }

        it 'matches' do
          expect(node).to be_class_constructor
        end
      end

      context 'Struct definition with a numblock' do
        let(:src) { 'Struct.new(:foo, :bar) { do_something(_1) }' }

        it 'matches' do
          expect(node).to be_class_constructor
        end
      end
    end

    context 'using Ruby >= 3.2', :ruby32 do
      context 'Data definition with a block' do
        let(:src) { 'Data.define(:foo, :bar) { def a = 42 }' }

        it 'matches' do
          expect(node).to be_class_constructor
        end
      end

      context 'Data definition with a numblock' do
        let(:src) { 'Data.define(:foo, :bar) { do_something(_1) }' }

        it 'matches' do
          expect(node).to be_class_constructor
        end
      end

      context 'Data definition without block' do
        let(:src) { 'Data.define(:foo, :bar)' }

        it 'matches' do
          expect(node).to be_class_constructor
        end
      end

      context '::Data' do
        let(:src) { '::Data.define(:foo, :bar) { def a = 42 }' }

        it 'matches' do
          expect(node).to be_class_constructor
        end
      end
    end
  end

  describe '#struct_constructor?' do
    context 'struct definition with a block' do
      let(:src) { 'Struct.new { a = 42 }' }

      it 'matches' do
        expect(node.struct_constructor?).to eq(node.body)
      end
    end

    context 'struct definition without block' do
      let(:src) { 'Struct.new(:foo, :bar)' }

      it 'does not match' do
        expect(node.struct_constructor?).to be_nil
      end
    end

    context '::Struct' do
      let(:src) { '::Struct.new { a = 42 }' }

      it 'matches' do
        expect(node.struct_constructor?).to eq(node.body)
      end
    end
  end

  describe '#class_definition?' do
    context 'without inheritance' do
      let(:src) { 'class Foo; a = 42; end' }

      it 'matches' do
        expect(node.class_definition?).to eq(node.body)
      end
    end

    context 'with inheritance' do
      let(:src) { 'class Foo < Bar; a = 42; end' }

      it 'matches' do
        expect(node.class_definition?).to eq(node.body)
      end
    end

    context 'with ::ClassName' do
      let(:src) { 'class ::Foo < Bar; a = 42; end' }

      it 'matches' do
        expect(node.class_definition?).to eq(node.body)
      end
    end

    context 'with Struct' do
      let(:src) do
        <<~RUBY
          Person = Struct.new(:name, :age) do
            a = 2
            def details; end
          end
        RUBY
      end

      it 'matches' do
        class_node = node.children.last
        expect(class_node.class_definition?).to eq(class_node.body)
      end

      context 'when using numbered parameter', :ruby27 do
        let(:src) do
          <<~RUBY
            Person = Struct.new(:name, :age) do
              do_something _1
            end
          RUBY
        end

        it 'matches' do
          class_node = node.children.last
          expect(class_node.class_definition?).to eq(class_node.body)
        end
      end
    end

    context 'constant defined as Struct without block' do
      let(:src) { 'Person = Struct.new(:name, :age)' }

      it 'does not match' do
        expect(node.class_definition?).to be_nil
      end
    end

    context 'with Class.new' do
      let(:src) do
        <<~RUBY
          Person = Class.new do
            a = 2
            def details; end
          end
        RUBY
      end

      it 'matches' do
        class_node = node.children.last
        expect(class_node.class_definition?).to eq(class_node.body)
      end

      context 'when using numbered parameter', :ruby27 do
        let(:src) do
          <<~RUBY
            Person = Class.new do
              do_something _1
            end
          RUBY
        end

        it 'matches' do
          class_node = node.children.last
          expect(class_node.class_definition?).to eq(class_node.body)
        end
      end
    end

    context 'namespaced class' do
      let(:src) do
        <<~RUBY
          class Foo::Bar::Baz
            BAZ = 2
            def variables; end
          end
        RUBY
      end

      it 'matches' do
        expect(node.class_definition?).to eq(node.body)
      end
    end

    context 'with self singleton class' do
      let(:src) do
        <<~RUBY
          class << self
            BAZ = 2
            def variables; end
          end
        RUBY
      end

      it 'matches' do
        expect(node.class_definition?).to eq(node.body)
      end
    end

    context 'with object singleton class' do
      let(:src) do
        <<~RUBY
          class << foo
            BAZ = 2
            def variables; end
          end
        RUBY
      end

      it 'matches' do
        expect(node.class_definition?).to eq(node.body)
      end
    end
  end

  describe '#module_definition?' do
    context 'using module keyword' do
      let(:src) { 'module Foo; A = 42; end' }

      it 'matches' do
        expect(node.module_definition?).to eq(node.body)
      end
    end

    context 'with ::ModuleName' do
      let(:src) { 'module ::Foo; A = 42; end' }

      it 'matches' do
        expect(node.module_definition?).to eq(node.body)
      end
    end

    context 'with Module.new' do
      let(:src) do
        <<~RUBY
          Person = Module.new do
            a = 2
            def details; end
          end
        RUBY
      end

      it 'matches' do
        module_node = node.children.last
        expect(module_node.module_definition?).to eq(module_node.body)
      end

      context 'when using numbered parameter', :ruby27 do
        let(:src) do
          <<~RUBY
            Person = Module.new do
              do_something _1
            end
          RUBY
        end

        it 'matches' do
          module_node = node.children.last
          expect(module_node.module_definition?).to eq(module_node.body)
        end
      end
    end

    context 'prepend Module.new' do
      let(:src) do
        <<~RUBY
          prepend(Module.new do
            a = 2
            def details; end
          end)
        RUBY
      end

      it 'matches' do
        module_node = node.children.last
        expect(module_node.module_definition?).to eq(module_node.body)
      end
    end

    context 'nested modules' do
      let(:src) do
        <<~RUBY
          module Foo
            module Bar
              BAZ = 2
              def variables; end
            end
          end
        RUBY
      end

      it 'matches' do
        expect(node.module_definition?).to eq(node.body)
      end
    end

    context 'namespaced modules' do
      let(:src) do
        <<~RUBY
          module Foo::Bar::Baz
            BAZ = 2
            def variables; end
          end
        RUBY
      end

      it 'matches' do
        expect(node.module_definition?).to eq(node.body)
      end
    end

    context 'included module definition' do
      let(:src) do
        <<~RUBY
          include(Module.new do
            BAZ = 2
            def variables; end
          end)
        RUBY
      end

      it 'matches' do
        module_node = node.children.last
        expect(module_node.module_definition?).to eq(module_node.body)
      end
    end
  end

  describe '#parent_module_name' do
    subject(:parent_module_name) { node.parent_module_name }

    context 'when node on top level' do
      let(:src) { 'def config; end' }

      it { is_expected.to eq 'Object' }
    end

    context 'when node on module' do
      let(:src) do
        <<~RUBY
          module Foo
            >>attr_reader :config<<
          end
        RUBY
      end

      it { is_expected.to eq 'Foo' }
    end

    context 'when node on singleton class' do
      let(:src) do
        <<~RUBY
          module Foo
            class << self
              >>attr_reader :config<<
            end
          end
        RUBY
      end

      it { is_expected.to eq 'Foo::#<Class:Foo>' }
    end

    context 'when node on class in singleton class' do
      let(:src) do
        <<~RUBY
          module Foo
            class << self
              class Bar
                >>attr_reader :config<<
              end
            end
          end
        RUBY
      end

      it { is_expected.to eq 'Foo::#<Class:Foo>::Bar' }
    end

    context 'when node nested in an unknown block' do
      let(:src) do
        <<~RUBY
          module Foo
            foo do
              class Bar
                >>attr_reader :config<<
              end
            end
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when node nested in a class << exp' do
      let(:src) do
        <<~RUBY
          class A
            class << expr
              >>attr_reader :config<<
            end
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#numeric_type?' do
    context 'when integer literal' do
      let(:src) { '42' }

      it 'is true' do
        expect(node).to be_numeric_type
      end
    end

    context 'when float literal' do
      let(:src) { '42.0' }

      it 'is true' do
        expect(node).to be_numeric_type
      end
    end

    context 'when rational literal' do
      let(:src) { '42r' }

      it 'is true' do
        expect(node).to be_numeric_type
      end
    end

    context 'when complex literal' do
      let(:src) { '42i' }

      it 'is true' do
        expect(node).to be_numeric_type
      end
    end

    context 'when complex literal whose imaginary part is a rational' do
      let(:src) { '42ri' }

      it 'is true' do
        expect(node).to be_numeric_type
      end
    end

    context 'when string literal' do
      let(:src) { '"42"' }

      it 'is true' do
        expect(node).not_to be_numeric_type
      end
    end
  end

  describe '#conditional?' do
    context 'when `if` node' do
      let(:src) do
        <<~RUBY
          if condition
          end
        RUBY
      end

      it 'is true' do
        expect(node).to be_conditional
      end
    end

    context 'when `while` node' do
      let(:src) do
        <<~RUBY
          while condition
          end
        RUBY
      end

      it 'is true' do
        expect(node).to be_conditional
      end
    end

    context 'when `until` node' do
      let(:src) do
        <<~RUBY
          until condition
          end
        RUBY
      end

      it 'is true' do
        expect(node).to be_conditional
      end
    end

    context 'when `case` node' do
      let(:src) do
        <<~RUBY
          case condition
          when foo
          end
        RUBY
      end

      it 'is true' do
        expect(node).to be_conditional
      end
    end

    context 'when `case_match` node', :ruby27 do
      let(:src) do
        <<~RUBY
          case pattern
          in foo
          end
        RUBY
      end

      it 'is true' do
        expect(node).to be_conditional
      end
    end

    context 'when post condition loop node' do
      let(:src) do
        <<~RUBY
          begin
          end while condition
        RUBY
      end

      it 'is false' do
        expect(node).not_to be_conditional
      end
    end
  end

  describe '*_type? methods on Node' do
    Parser::Meta::NODE_TYPES.each do |node_type|
      method_name = "#{node_type.to_s.gsub(/\W/, '')}_type?"

      it "is not of #{method_name}" do
        expect(described_class.allocate.public_send(method_name)).to be(false)
      end
    end
  end
end
