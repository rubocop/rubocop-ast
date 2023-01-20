# frozen_string_literal: true

RSpec.describe RuboCop::AST::SuperNode do
  subject(:super_node) { ast }

  let(:ast) { parse_source(source).ast }

  describe '.new' do
    context 'with a super node' do
      let(:source) { 'super(:baz)' }

      it { is_expected.to be_a(described_class) }
    end

    context 'with a zsuper node' do
      let(:source) { 'super' }

      it { is_expected.to be_a(described_class) }
    end
  end

  describe '#receiver' do
    let(:source) { 'super(foo)' }

    it { expect(super_node.receiver).to be_nil }
  end

  describe '#method_name' do
    let(:source) { 'super(foo)' }

    it { expect(super_node.method_name).to eq(:super) }
  end

  describe '#selector' do
    let(:source) { 'super(foo)' }

    it { expect(super_node.selector.source).to eq('super') }
  end

  describe '#method?' do
    context 'when message matches' do
      context 'when argument is a symbol' do
        let(:source) { 'super(:baz)' }

        it { is_expected.to be_method(:super) }
      end

      context 'when argument is a string' do
        let(:source) { 'super(:baz)' }

        it { is_expected.to be_method('super') }
      end
    end

    context 'when message does not match' do
      context 'when argument is a symbol' do
        let(:source) { 'super(:baz)' }

        it { is_expected.not_to be_method(:foo) }
      end

      context 'when argument is a string' do
        let(:source) { 'super(:baz)' }

        it { is_expected.not_to be_method('foo') }
      end
    end
  end

  describe '#macro?' do
    subject(:super_node) { ast.children[2] }

    let(:source) do
      ['def initialize',
       '  super(foo)',
       'end'].join("\n")
    end

    it { is_expected.not_to be_macro }
  end

  describe '#command?' do
    context 'when argument is a symbol' do
      let(:source) { 'super(foo)' }

      it { is_expected.to be_command(:super) }
    end

    context 'when argument is a string' do
      let(:source) { 'super(foo)' }

      it { is_expected.to be_command('super') }
    end
  end

  describe '#setter_method?' do
    let(:source) { 'super(foo)' }

    it { is_expected.not_to be_setter_method }
  end

  describe '#operator_method?' do
    let(:source) { 'super(foo)' }

    it { is_expected.not_to be_operator_method }
  end

  describe '#comparison_method?' do
    let(:source) { 'super(foo)' }

    it { is_expected.not_to be_comparison_method }
  end

  describe '#assignment_method?' do
    let(:source) { 'super(foo)' }

    it { is_expected.not_to be_assignment_method }
  end

  describe '#dot?' do
    let(:source) { 'super(foo)' }

    it { is_expected.not_to be_dot }
  end

  describe '#double_colon?' do
    let(:source) { 'super(foo)' }

    it { is_expected.not_to be_double_colon }
  end

  describe '#self_receiver?' do
    let(:source) { 'super(foo)' }

    it { is_expected.not_to be_self_receiver }
  end

  describe '#const_receiver?' do
    let(:source) { 'super(foo)' }

    it { is_expected.not_to be_const_receiver }
  end

  describe '#implicit_call?' do
    let(:source) { 'super(foo)' }

    it { is_expected.not_to be_implicit_call }
  end

  describe '#predicate_method?' do
    let(:source) { 'super(foo)' }

    it { is_expected.not_to be_predicate_method }
  end

  describe '#bang_method?' do
    let(:source) { 'super(foo)' }

    it { is_expected.not_to be_bang_method }
  end

  describe '#camel_case_method?' do
    let(:source) { 'super(foo)' }

    it { is_expected.not_to be_camel_case_method }
  end

  describe '#parenthesized?' do
    context 'with no arguments' do
      context 'when not using parentheses' do
        let(:source) { 'super' }

        it { is_expected.not_to be_parenthesized }
      end

      context 'when using parentheses' do
        let(:source) { 'foo.bar()' }

        it { is_expected.to be_parenthesized }
      end
    end

    context 'with arguments' do
      context 'when not using parentheses' do
        let(:source) { 'foo.bar :baz' }

        it { is_expected.not_to be_parenthesized }
      end

      context 'when using parentheses' do
        let(:source) { 'foo.bar(:baz)' }

        it { is_expected.to be_parenthesized }
      end
    end
  end

  describe '#block_argument?' do
    context 'with a block argument' do
      let(:source) { 'super(&baz)' }

      it { is_expected.to be_block_argument }
    end

    context 'with no arguments' do
      let(:source) { 'super' }

      it { is_expected.not_to be_block_argument }
    end

    context 'with regular arguments' do
      let(:source) { 'super(:baz)' }

      it { is_expected.not_to be_block_argument }
    end

    context 'with mixed arguments' do
      let(:source) { 'super(:baz, &qux)' }

      it { is_expected.to be_block_argument }
    end
  end

  describe '#block_literal?' do
    context 'with a block literal' do
      subject(:super_node) { ast.children[0] }

      let(:source) { 'super { |q| baz(q) }' }

      it { is_expected.to be_block_literal }
    end

    context 'with a block argument' do
      let(:source) { 'super(&baz)' }

      it { is_expected.not_to be_block_literal }
    end

    context 'with no block' do
      let(:source) { 'super' }

      it { is_expected.not_to be_block_literal }
    end
  end

  describe '#block_node' do
    context 'with a block literal' do
      subject(:super_node) { ast.children[0] }

      let(:source) { 'super { |q| baz(q) }' }

      it { expect(super_node.block_node).to be_block_type }
    end

    context 'with a block argument' do
      let(:source) { 'super(&baz)' }

      it { expect(super_node.block_node).to be_nil }
    end

    context 'with no block' do
      let(:source) { 'super' }

      it { expect(super_node.block_node).to be_nil }
    end
  end

  describe '#arguments' do
    context 'with no arguments' do
      let(:source) { 'super' }

      it { expect(super_node.arguments).to be_empty }
    end

    context 'with a single literal argument' do
      let(:source) { 'super(:baz)' }

      it { expect(super_node.arguments.size).to eq(1) }
    end

    context 'with a single splat argument' do
      let(:source) { 'super(*baz)' }

      it { expect(super_node.arguments.size).to eq(1) }
    end

    context 'with multiple literal arguments' do
      let(:source) { 'super(:baz, :qux)' }

      it { expect(super_node.arguments.size).to eq(2) }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'super(:baz, *qux)' }

      it { expect(super_node.arguments.size).to eq(2) }
    end
  end

  describe '#first_argument' do
    context 'with no arguments' do
      let(:source) { 'super' }

      it { expect(super_node.first_argument).to be_nil }
    end

    context 'with a single literal argument' do
      let(:source) { 'super(:baz)' }

      it { expect(super_node.first_argument).to be_sym_type }
    end

    context 'with a single splat argument' do
      let(:source) { 'super(*baz)' }

      it { expect(super_node.first_argument).to be_splat_type }
    end

    context 'with multiple literal arguments' do
      let(:source) { 'super(:baz, :qux)' }

      it { expect(super_node.first_argument).to be_sym_type }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'superr(:baz, *qux)' }

      it { expect(super_node.first_argument).to be_sym_type }
    end
  end

  describe '#last_argument' do
    context 'with no arguments' do
      let(:source) { 'super' }

      it { expect(super_node.last_argument).to be_nil }
    end

    context 'with a single literal argument' do
      let(:source) { 'super(:baz)' }

      it { expect(super_node.last_argument).to be_sym_type }
    end

    context 'with a single splat argument' do
      let(:source) { 'super(*baz)' }

      it { expect(super_node.last_argument).to be_splat_type }
    end

    context 'with multiple literal arguments' do
      let(:source) { 'super(:baz, :qux)' }

      it { expect(super_node.last_argument).to be_sym_type }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'super(:baz, *qux)' }

      it { expect(super_node.last_argument).to be_splat_type }
    end
  end

  describe '#arguments?' do
    context 'with no arguments' do
      let(:source) { 'super' }

      it { is_expected.not_to be_arguments }
    end

    context 'with a single literal argument' do
      let(:source) { 'super(:baz)' }

      it { is_expected.to be_arguments }
    end

    context 'with a single splat argument' do
      let(:source) { 'super(*baz)' }

      it { is_expected.to be_arguments }
    end

    context 'with multiple literal arguments' do
      let(:source) { 'super(:baz, :qux)' }

      it { is_expected.to be_arguments }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'super(:baz, *qux)' }

      it { is_expected.to be_arguments }
    end
  end

  describe '#splat_argument?' do
    context 'with a splat argument' do
      let(:source) { 'super(*baz)' }

      it { is_expected.to be_splat_argument }
    end

    context 'with no arguments' do
      let(:source) { 'super' }

      it { is_expected.not_to be_splat_argument }
    end

    context 'with regular arguments' do
      let(:source) { 'super(:baz)' }

      it { is_expected.not_to be_splat_argument }
    end

    context 'with mixed arguments' do
      let(:source) { 'super(:baz, *qux)' }

      it { is_expected.to be_splat_argument }
    end
  end
end
