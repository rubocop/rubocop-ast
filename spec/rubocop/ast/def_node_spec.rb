# frozen_string_literal: true

RSpec.describe RuboCop::AST::DefNode do
  subject(:def_node) { parse_source(source).ast }

  describe '.new' do
    context 'with a def node' do
      let(:source) { 'def foo(bar); end' }

      it { is_expected.to be_a(described_class) }
    end

    context 'with a defs node' do
      let(:source) { 'def self.foo(bar); end' }

      it { is_expected.to be_a(described_class) }
    end
  end

  describe '#method_name' do
    context 'with a plain method' do
      let(:source) { 'def foo; end' }

      it { expect(def_node.method_name).to eq(:foo) }
    end

    context 'with a setter method' do
      let(:source) { 'def foo=(bar); end' }

      it { expect(def_node.method_name).to eq(:foo=) }
    end

    context 'with an operator method' do
      let(:source) { 'def ==(bar); end' }

      it { expect(def_node.method_name).to eq(:==) }
    end

    context 'with a unary method' do
      let(:source) { 'def -@; end' }

      it { expect(def_node.method_name).to eq(:-@) }
    end
  end

  describe '#method?' do
    context 'when message matches' do
      context 'when argument is a symbol' do
        let(:source) { 'bar(:baz)' }

        it { is_expected.to be_method(:bar) }
      end

      context 'when argument is a string' do
        let(:source) { 'bar(:baz)' }

        it { is_expected.to be_method('bar') }
      end
    end

    context 'when message does not match' do
      context 'when argument is a symbol' do
        let(:source) { 'bar(:baz)' }

        it { is_expected.not_to be_method(:foo) }
      end

      context 'when argument is a string' do
        let(:source) { 'bar(:baz)' }

        it { is_expected.not_to be_method('foo') }
      end
    end
  end

  describe '#arguments' do
    context 'with no arguments' do
      let(:source) { 'def foo; end' }

      it { expect(def_node.arguments).to be_empty }
    end

    context 'with a single regular argument' do
      let(:source) { 'def foo(bar); end' }

      it { expect(def_node.arguments.size).to eq(1) }
    end

    context 'with a single rest argument' do
      let(:source) { 'def foo(*baz); end' }

      it { expect(def_node.arguments.size).to eq(1) }
    end

    context 'with multiple regular arguments' do
      let(:source) { 'def foo(bar, baz); end' }

      it { expect(def_node.arguments.size).to eq(2) }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'def foo(bar, *baz); end' }

      it { expect(def_node.arguments.size).to eq(2) }
    end

    context 'with argument forwarding', :ruby27 do
      let(:source) { 'def foo(...); end' }

      it { expect(def_node.arguments.size).to eq(1) }
    end
  end

  describe '#first_argument' do
    context 'with no arguments' do
      let(:source) { 'def foo; end' }

      it { expect(def_node.first_argument).to be_nil }
    end

    context 'with a single regular argument' do
      let(:source) { 'def foo(bar); end' }

      it { expect(def_node.first_argument).to be_arg_type }
    end

    context 'with a single rest argument' do
      let(:source) { 'def foo(*bar); end' }

      it { expect(def_node.first_argument).to be_restarg_type }
    end

    context 'with a single keyword argument' do
      let(:source) { 'def foo(bar: :baz); end' }

      it { expect(def_node.first_argument).to be_kwoptarg_type }
    end

    context 'with multiple regular arguments' do
      let(:source) { 'def foo(bar, baz); end' }

      it { expect(def_node.first_argument).to be_arg_type }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'def foo(bar, *baz); end' }

      it { expect(def_node.first_argument).to be_arg_type }
    end
  end

  describe '#last_argument' do
    context 'with no arguments' do
      let(:source) { 'def foo; end' }

      it { expect(def_node.last_argument).to be_nil }
    end

    context 'with a single regular argument' do
      let(:source) { 'def foo(bar); end' }

      it { expect(def_node.last_argument).to be_arg_type }
    end

    context 'with a single rest argument' do
      let(:source) { 'def foo(*bar); end' }

      it { expect(def_node.last_argument).to be_restarg_type }
    end

    context 'with a single keyword argument' do
      let(:source) { 'def foo(bar: :baz); end' }

      it { expect(def_node.last_argument).to be_kwoptarg_type }
    end

    context 'with multiple regular arguments' do
      let(:source) { 'def foo(bar, baz); end' }

      it { expect(def_node.last_argument).to be_arg_type }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'def foo(bar, *baz); end' }

      it { expect(def_node.last_argument).to be_restarg_type }
    end
  end

  describe '#arguments?' do
    context 'with no arguments' do
      let(:source) { 'def foo; end' }

      it { is_expected.not_to be_arguments }
    end

    context 'with a single regular argument' do
      let(:source) { 'def foo(bar); end' }

      it { is_expected.to be_arguments }
    end

    context 'with a single rest argument' do
      let(:source) { 'def foo(*bar); end' }

      it { is_expected.to be_arguments }
    end

    context 'with a single keyword argument' do
      let(:source) { 'def foo(bar: :baz); end' }

      it { is_expected.to be_arguments }
    end

    context 'with multiple regular arguments' do
      let(:source) { 'def foo(bar, baz); end' }

      it { is_expected.to be_arguments }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'def foo(bar, *baz); end' }

      it { is_expected.to be_arguments }
    end
  end

  describe '#rest_argument?' do
    context 'with a rest argument' do
      let(:source) { 'def foo(*bar); end' }

      it { is_expected.to be_rest_argument }
    end

    context 'with no arguments' do
      let(:source) { 'def foo; end' }

      it { is_expected.not_to be_rest_argument }
    end

    context 'with regular arguments' do
      let(:source) { 'def foo(bar); end' }

      it { is_expected.not_to be_rest_argument }
    end

    context 'with mixed arguments' do
      let(:source) { 'def foo(bar, *baz); end' }

      it { is_expected.to be_rest_argument }
    end
  end

  describe '#operator_method?' do
    context 'with a binary operator method' do
      let(:source) { 'def ==(bar); end' }

      it { is_expected.to be_operator_method }
    end

    context 'with a unary operator method' do
      let(:source) { 'def -@; end' }

      it { is_expected.to be_operator_method }
    end

    context 'with a setter method' do
      let(:source) { 'def foo=(bar); end' }

      it { is_expected.not_to be_operator_method }
    end

    context 'with a regular method' do
      let(:source) { 'def foo(bar); end' }

      it { is_expected.not_to be_operator_method }
    end
  end

  describe '#comparison_method?' do
    context 'with a comparison method' do
      let(:source) { 'def <=(bar); end' }

      it { is_expected.to be_comparison_method }
    end

    context 'with a regular method' do
      let(:source) { 'def foo(bar); end' }

      it { is_expected.not_to be_comparison_method }
    end
  end

  describe '#assignment_method?' do
    context 'with an assignment method' do
      let(:source) { 'def foo=(bar); end' }

      it { is_expected.to be_assignment_method }
    end

    context 'with a bracket assignment method' do
      let(:source) { 'def []=(bar); end' }

      it { is_expected.to be_assignment_method }
    end

    context 'with a comparison method' do
      let(:source) { 'def ==(bar); end' }

      it { is_expected.not_to be_assignment_method }
    end

    context 'with a regular method' do
      let(:source) { 'def foo(bar); end' }

      it { is_expected.not_to be_assignment_method }
    end
  end

  describe '#void_context?' do
    context 'with an initializer method' do
      let(:source) { 'def initialize(bar); end' }

      it { is_expected.to be_void_context }
    end

    context 'with a class method called "initialize"' do
      let(:source) { 'def self.initialize(bar); end' }

      it { is_expected.not_to be_void_context }
    end

    context 'with a regular assignment method' do
      let(:source) { 'def foo=(bar); end' }

      it { is_expected.to be_void_context }
    end

    context 'with a bracket assignment method' do
      let(:source) { 'def []=(bar); end' }

      it { is_expected.to be_void_context }
    end

    context 'with a comparison method' do
      let(:source) { 'def ==(bar); end' }

      it { is_expected.not_to be_void_context }
    end

    context 'with a regular method' do
      let(:source) { 'def foo(bar); end' }

      it { is_expected.not_to be_void_context }
    end
  end

  context 'when using Ruby 2.7 or newer', :ruby27 do
    describe '#argument_forwarding?' do
      let(:source) { 'def foo(...); end' }

      it { is_expected.to be_argument_forwarding }
    end
  end

  describe '#receiver' do
    context 'with an instance method definition' do
      let(:source) { 'def foo(bar); end' }

      it { expect(def_node.receiver).to be_nil }
    end

    context 'with a class method definition' do
      let(:source) { 'def self.foo(bar); end' }

      it { expect(def_node.receiver).to be_self_type }
    end

    context 'with a singleton method definition' do
      let(:source) { 'def Foo.bar(baz); end' }

      it { expect(def_node.receiver).to be_const_type }
    end
  end

  describe '#self_receiver?' do
    context 'with an instance method definition' do
      let(:source) { 'def foo(bar); end' }

      it { is_expected.not_to be_self_receiver }
    end

    context 'with a class method definition' do
      let(:source) { 'def self.foo(bar); end' }

      it { is_expected.to be_self_receiver }
    end

    context 'with a singleton method definition' do
      let(:source) { 'def Foo.bar(baz); end' }

      it { is_expected.not_to be_self_receiver }
    end
  end

  describe '#const_receiver?' do
    context 'with an instance method definition' do
      let(:source) { 'def foo(bar); end' }

      it { is_expected.not_to be_const_receiver }
    end

    context 'with a class method definition' do
      let(:source) { 'def self.foo(bar); end' }

      it { is_expected.not_to be_const_receiver }
    end

    context 'with a singleton method definition' do
      let(:source) { 'def Foo.bar(baz); end' }

      it { is_expected.to be_const_receiver }
    end
  end

  describe '#predicate_method?' do
    context 'with a predicate method' do
      let(:source) { 'def foo?(bar); end' }

      it { is_expected.to be_predicate_method }
    end

    context 'with a bang method' do
      let(:source) { 'def foo!(bar); end' }

      it { is_expected.not_to be_predicate_method }
    end

    context 'with a regular method' do
      let(:source) { 'def foo(bar); end' }

      it { is_expected.not_to be_predicate_method }
    end
  end

  describe '#bang_method?' do
    context 'with a bang method' do
      let(:source) { 'def foo!(bar); end' }

      it { is_expected.to be_bang_method }
    end

    context 'with a predicate method' do
      let(:source) { 'def foo?(bar); end' }

      it { is_expected.not_to be_bang_method }
    end

    context 'with a regular method' do
      let(:source) { 'def foo(bar); end' }

      it { is_expected.not_to be_bang_method }
    end
  end

  describe '#camel_case_method?' do
    context 'with a camel case method' do
      let(:source) { 'def Foo(bar); end' }

      it { is_expected.to be_camel_case_method }
    end

    context 'with a regular method' do
      let(:source) { 'def foo(bar); end' }

      it { is_expected.not_to be_camel_case_method }
    end
  end

  describe '#block_argument?' do
    context 'with a block argument' do
      let(:source) { 'def foo(&bar); end' }

      it { is_expected.to be_block_argument }
    end

    context 'with no arguments' do
      let(:source) { 'def foo; end' }

      it { is_expected.not_to be_block_argument }
    end

    context 'with regular arguments' do
      let(:source) { 'def foo(bar); end' }

      it { is_expected.not_to be_block_argument }
    end

    context 'with mixed arguments' do
      let(:source) { 'def foo(bar, &baz); end' }

      it { is_expected.to be_block_argument }
    end
  end

  describe '#body' do
    context 'with no body' do
      let(:source) { 'def foo(bar); end' }

      it { expect(def_node.body).to be_nil }
    end

    context 'with a single expression body' do
      let(:source) { 'def foo(bar); baz; end' }

      it { expect(def_node.body).to be_send_type }
    end

    context 'with a multi-expression body' do
      let(:source) { 'def foo(bar); baz; qux; end' }

      it { expect(def_node.body).to be_begin_type }
    end
  end

  describe '#endless?' do
    context 'with standard method definition' do
      let(:source) { 'def foo; 42; end' }

      it { is_expected.not_to be_endless }
    end

    context 'with endless method definition', :ruby30 do
      let(:source) { 'def foo() = 42' }

      it { is_expected.to be_endless }
    end
  end
end
