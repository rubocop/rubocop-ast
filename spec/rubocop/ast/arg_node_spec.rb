# frozen_string_literal: true

RSpec.describe RuboCop::AST::ArgNode do
  let(:args_node) { parse_source(source).ast.arguments }
  let(:arg_node) { args_node.first }

  describe '.new' do
    context 'with a method definition' do
      let(:source) { 'def foo(x) end' }

      it { expect(arg_node).to be_a(described_class) }
    end

    context 'with a block' do
      let(:source) { 'foo { |x| bar }' }

      if RuboCop::AST::Builder.emit_procarg0
        it { expect(arg_node).to be_a(RuboCop::AST::Procarg0Node) }
      else
        it { expect(arg_node).to be_a(described_class) }
      end
    end

    context 'with a lambda literal' do
      let(:source) { '-> (x) { bar }' }

      it { expect(arg_node).to be_a(described_class) }
    end

    context 'with a keyword argument' do
      let(:source) { 'def foo(x:) end' }

      it { expect(arg_node).to be_a(described_class) }
    end

    context 'with an optional argument' do
      let(:source) { 'def foo(x = 42) end' }

      it { expect(arg_node).to be_a(described_class) }
    end

    context 'with an optional keyword argument' do
      let(:source) { 'def foo(x: 42) end' }

      it { expect(arg_node).to be_a(described_class) }
    end

    context 'with a splatted argument' do
      let(:source) { 'def foo(*x) end' }

      it { expect(arg_node).to be_a(described_class) }
    end

    context 'with a double splatted argument' do
      let(:source) { 'def foo(**x) end' }

      it { expect(arg_node).to be_a(described_class) }
    end

    context 'with a block argument' do
      let(:source) { 'def foo(&x) end' }

      it { expect(arg_node).to be_a(described_class) }
    end

    context 'with a shadow argument' do
      let(:source) { 'foo { |; x| }' }

      it { expect(arg_node).to be_a(described_class) }
    end

    context 'with argument forwarding' do
      context 'with Ruby >= 2.7', :ruby27 do
        let(:source) { 'def foo(...); end' }

        if RuboCop::AST::Builder.emit_forward_arg
          it { expect(arg_node).to be_a(described_class) }
        else
          it { expect(arg_node).to be_forward_args_type }
        end
      end

      context 'with Ruby >= 3.0', :ruby30 do
        let(:source) { 'def foo(x, ...); end' }
        let(:arg_node) { args_node.last }

        it { expect(arg_node).to be_a(described_class) }
      end
    end
  end

  describe '#name' do
    subject { arg_node.name }

    context 'with a regular argument' do
      let(:source) { 'def foo(x) end' }

      it { is_expected.to eq(:x) }
    end

    context 'with a block' do
      let(:source) { 'foo { |x| x }' }

      it { is_expected.to eq(:x) }
    end

    context 'with a keyword argument' do
      let(:source) { 'def foo(x:) end' }

      it { is_expected.to eq(:x) }
    end

    context 'with an optional argument' do
      let(:source) { 'def foo(x = 42) end' }

      it { is_expected.to eq(:x) }
    end

    context 'with an optional keyword argument' do
      let(:source) { 'def foo(x: 42) end' }

      it { is_expected.to eq(:x) }
    end

    context 'with a splatted argument' do
      let(:source) { 'def foo(*x) end' }

      it { is_expected.to eq(:x) }
    end

    context 'with a nameless splatted argument' do
      let(:source) { 'def foo(*) end' }

      it { is_expected.to be_nil }
    end

    context 'with a double splatted argument' do
      let(:source) { 'def foo(**x) end' }

      it { is_expected.to eq(:x) }
    end

    context 'with a nameless double splatted argument' do
      let(:source) { 'def foo(**) end' }

      it { is_expected.to be_nil }
    end

    context 'with a block argument' do
      let(:source) { 'def foo(&x) end' }

      it { is_expected.to eq(:x) }
    end

    context 'with a shadow argument' do
      let(:source) { 'foo { |; x| x = 5 }' }

      it { is_expected.to eq(:x) }
    end

    context 'with argument forwarding' do
      context 'with Ruby >= 2.7', :ruby27 do
        let(:source) { 'def foo(...); end' }

        it { is_expected.to be_nil } if RuboCop::AST::Builder.emit_forward_arg
      end

      context 'with Ruby >= 3.0', :ruby30 do
        let(:source) { 'def foo(x, ...); end' }
        let(:arg_node) { args_node.last }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#default_value' do
    include AST::Sexp

    subject { arg_node.default_value }

    context 'with a regular argument' do
      let(:source) { 'def foo(x) end' }

      it { is_expected.to be_nil }
    end

    context 'with a block' do
      let(:source) { 'foo { |x| x }' }

      it { is_expected.to be_nil }
    end

    context 'with an optional argument' do
      let(:source) { 'def foo(x = 42) end' }

      it { is_expected.to eq(s(:int, 42)) }
    end

    context 'with an optional keyword argument' do
      let(:source) { 'def foo(x: 42) end' }

      it { is_expected.to eq(s(:int, 42)) }
    end

    context 'with a splatted argument' do
      let(:source) { 'def foo(*x) end' }

      it { is_expected.to be_nil }
    end

    context 'with a double splatted argument' do
      let(:source) { 'def foo(**x) end' }

      it { is_expected.to be_nil }
    end

    context 'with a block argument' do
      let(:source) { 'def foo(&x) end' }

      it { is_expected.to be_nil }
    end

    context 'with a shadow argument' do
      let(:source) { 'foo { |; x| x = 5 }' }

      it { is_expected.to be_nil }
    end

    context 'with argument forwarding' do
      context 'with Ruby >= 2.7', :ruby27 do
        let(:source) { 'def foo(...); end' }

        it { is_expected.to be_nil } if RuboCop::AST::Builder.emit_forward_arg
      end

      context 'with Ruby >= 3.0', :ruby30 do
        let(:source) { 'def foo(x, ...); end' }
        let(:arg_node) { args_node.last }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#default?' do
    subject { arg_node.default? }

    context 'with a regular argument' do
      let(:source) { 'def foo(x) end' }

      it { is_expected.to be(false) }
    end

    context 'with a block' do
      let(:source) { 'foo { |x| x }' }

      it { is_expected.to be(false) }
    end

    context 'with an optional argument' do
      let(:source) { 'def foo(x = 42) end' }

      it { is_expected.to be(true) }
    end

    context 'with an optional keyword argument' do
      let(:source) { 'def foo(x: 42) end' }

      it { is_expected.to be(true) }
    end

    context 'with a splatted argument' do
      let(:source) { 'def foo(*x) end' }

      it { is_expected.to be(false) }
    end

    context 'with a double splatted argument' do
      let(:source) { 'def foo(**x) end' }

      it { is_expected.to be(false) }
    end

    context 'with a block argument' do
      let(:source) { 'def foo(&x) end' }

      it { is_expected.to be(false) }
    end

    context 'with a shadow argument' do
      let(:source) { 'foo { |; x| x = 5 }' }

      it { is_expected.to be(false) }
    end

    context 'with argument forwarding' do
      context 'with Ruby >= 2.7', :ruby27 do
        let(:source) { 'def foo(...); end' }

        it { is_expected.to be(false) } if RuboCop::AST::Builder.emit_forward_arg
      end

      context 'with Ruby >= 3.0', :ruby30 do
        let(:source) { 'def foo(x, ...); end' }
        let(:arg_node) { args_node.last }

        it { is_expected.to be(false) }
      end
    end
  end
end
