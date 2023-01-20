# frozen_string_literal: true

RSpec.describe RuboCop::AST::YieldNode do
  subject(:yield_node) { ast }

  let(:ast) { parse_source(source).ast }

  describe '.new' do
    let(:source) { 'yield :foo, :bar' }

    it { is_expected.to be_a(described_class) }
  end

  describe '#receiver' do
    let(:source) { 'yield :foo, :bar' }

    it { expect(yield_node.receiver).to be_nil }
  end

  describe '#method_name' do
    let(:source) { 'yield :foo, :bar' }

    it { expect(yield_node.method_name).to eq(:yield) }
  end

  describe '#selector' do
    let(:source) { 'yield :foo, :bar' }

    it { expect(yield_node.selector.source).to eq('yield') }
  end

  describe '#method?' do
    context 'when message matches' do
      context 'when argument is a symbol' do
        let(:source) { 'yield :foo' }

        it { is_expected.to be_method(:yield) }
      end

      context 'when argument is a string' do
        let(:source) { 'yield :foo' }

        it { is_expected.to be_method('yield') }
      end
    end

    context 'when message does not match' do
      context 'when argument is a symbol' do
        let(:source) { 'yield :bar' }

        it { is_expected.not_to be_method(:foo) }
      end

      context 'when argument is a string' do
        let(:source) { 'yield :bar' }

        it { is_expected.not_to be_method('foo') }
      end
    end
  end

  describe '#macro?' do
    subject(:yield_node) { ast.children[2] }

    let(:source) do
      ['def give_me_bar',
       '  yield :bar',
       'end'].join("\n")
    end

    it { is_expected.not_to be_macro }
  end

  describe '#command?' do
    context 'when argument is a symbol' do
      let(:source) { 'yield :bar' }

      it { is_expected.to be_command(:yield) }
    end

    context 'when argument is a string' do
      let(:source) { 'yield :bar' }

      it { is_expected.to be_command('yield') }
    end
  end

  describe '#arguments' do
    context 'with no arguments' do
      let(:source) { 'yield' }

      it { expect(yield_node.arguments).to be_empty }
    end

    context 'with a single literal argument' do
      let(:source) { 'yield :foo' }

      it { expect(yield_node.arguments.size).to eq(1) }
    end

    context 'with a single splat argument' do
      let(:source) { 'yield *foo' }

      it { expect(yield_node.arguments.size).to eq(1) }
    end

    context 'with multiple literal arguments' do
      let(:source) { 'yield :foo, :bar' }

      it { expect(yield_node.arguments.size).to eq(2) }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'yield :foo, *bar' }

      it { expect(yield_node.arguments.size).to eq(2) }
    end
  end

  describe '#first_argument' do
    context 'with no arguments' do
      let(:source) { 'yield' }

      it { expect(yield_node.first_argument).to be_nil }
    end

    context 'with a single literal argument' do
      let(:source) { 'yield :foo' }

      it { expect(yield_node.first_argument).to be_sym_type }
    end

    context 'with a single splat argument' do
      let(:source) { 'yield *foo' }

      it { expect(yield_node.first_argument).to be_splat_type }
    end

    context 'with multiple literal arguments' do
      let(:source) { 'yield :foo, :bar' }

      it { expect(yield_node.first_argument).to be_sym_type }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'yield :foo, *bar' }

      it { expect(yield_node.first_argument).to be_sym_type }
    end
  end

  describe '#last_argument' do
    context 'with no arguments' do
      let(:source) { 'yield' }

      it { expect(yield_node.last_argument).to be_nil }
    end

    context 'with a single literal argument' do
      let(:source) { 'yield :foo' }

      it { expect(yield_node.last_argument).to be_sym_type }
    end

    context 'with a single splat argument' do
      let(:source) { 'yield *foo' }

      it { expect(yield_node.last_argument).to be_splat_type }
    end

    context 'with multiple literal arguments' do
      let(:source) { 'yield :foo, :bar' }

      it { expect(yield_node.last_argument).to be_sym_type }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'yield :foo, *bar' }

      it { expect(yield_node.last_argument).to be_splat_type }
    end
  end

  describe '#arguments?' do
    context 'with no arguments' do
      let(:source) { 'yield' }

      it { is_expected.not_to be_arguments }
    end

    context 'with a single literal argument' do
      let(:source) { 'yield :foo' }

      it { is_expected.to be_arguments }
    end

    context 'with a single splat argument' do
      let(:source) { 'yield *foo' }

      it { is_expected.to be_arguments }
    end

    context 'with multiple literal arguments' do
      let(:source) { 'yield :foo, :bar' }

      it { is_expected.to be_arguments }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'yield :foo, *bar' }

      it { is_expected.to be_arguments }
    end
  end

  describe '#parenthesized?' do
    context 'with no arguments' do
      context 'when not using parentheses' do
        let(:source) { 'yield' }

        it { is_expected.not_to be_parenthesized }
      end

      context 'when using parentheses' do
        let(:source) { 'yield()' }

        it { is_expected.to be_parenthesized }
      end
    end

    context 'with arguments' do
      context 'when not using parentheses' do
        let(:source) { 'yield :foo' }

        it { is_expected.not_to be_parenthesized }
      end

      context 'when using parentheses' do
        let(:source) { 'yield(:foo)' }

        it { is_expected.to be_parenthesized }
      end
    end
  end

  describe '#setter_method?' do
    let(:source) { 'yield :foo' }

    it { is_expected.not_to be_setter_method }
  end

  describe '#operator_method?' do
    let(:source) { 'yield :foo' }

    it { is_expected.not_to be_operator_method }
  end

  describe '#comparison_method?' do
    let(:source) { 'yield :foo' }

    it { is_expected.not_to be_comparison_method }
  end

  describe '#assignment_method?' do
    let(:source) { 'yield :foo' }

    it { is_expected.not_to be_assignment_method }
  end

  describe '#dot?' do
    let(:source) { 'yield :foo' }

    it { is_expected.not_to be_dot }
  end

  describe '#double_colon?' do
    let(:source) { 'yield :foo' }

    it { is_expected.not_to be_double_colon }
  end

  describe '#self_receiver?' do
    let(:source) { 'yield :foo' }

    it { is_expected.not_to be_self_receiver }
  end

  describe '#const_receiver?' do
    let(:source) { 'yield :foo' }

    it { is_expected.not_to be_const_receiver }
  end

  describe '#implicit_call?' do
    let(:source) { 'yield :foo' }

    it { is_expected.not_to be_implicit_call }
  end

  describe '#predicate_method?' do
    let(:source) { 'yield :foo' }

    it { is_expected.not_to be_predicate_method }
  end

  describe '#bang_method?' do
    let(:source) { 'yield :foo' }

    it { is_expected.not_to be_bang_method }
  end

  describe '#camel_case_method?' do
    let(:source) { 'yield :foo' }

    it { is_expected.not_to be_camel_case_method }
  end

  describe '#block_argument?' do
    let(:source) { 'yield :foo' }

    it { is_expected.not_to be_block_argument }
  end

  describe '#block_literal?' do
    let(:source) { 'yield :foo' }

    it { is_expected.not_to be_block_literal }
  end

  describe '#block_node' do
    let(:source) { 'yield :foo' }

    it { expect(yield_node.block_node).to be_nil }
  end

  describe '#splat_argument?' do
    context 'with a splat argument' do
      let(:source) { 'yield *foo' }

      it { is_expected.to be_splat_argument }
    end

    context 'with no arguments' do
      let(:source) { 'yield' }

      it { is_expected.not_to be_splat_argument }
    end

    context 'with regular arguments' do
      let(:source) { 'yield :foo' }

      it { is_expected.not_to be_splat_argument }
    end

    context 'with mixed arguments' do
      let(:source) { 'yield :foo, *bar' }

      it { is_expected.to be_splat_argument }
    end
  end
end
