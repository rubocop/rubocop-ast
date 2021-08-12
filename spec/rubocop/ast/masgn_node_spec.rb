# frozen_string_literal: true

RSpec.describe RuboCop::AST::MasgnNode do
  let(:masgn_node) { parse_source(source).ast }
  let(:source) { 'x, y = z' }

  describe '.new' do
    context 'with a `masgn` node' do
      it { expect(masgn_node).to be_a(described_class) }
    end
  end

  describe '#names' do
    subject { masgn_node.names }

    let(:source) { 'a, @b, @@c, $d, E, *f = z' }

    it { is_expected.to eq(%i[a @b @@c $d E f]) }

    context 'with nested `mlhs` nodes' do
      let(:source) { 'a, (b, c) = z' }

      it { is_expected.to eq(%i[a b c]) }
    end

    context 'with array setter' do
      let(:source) { 'a, b[c] = z' }

      it { is_expected.to eq(%i[a []=]) }
    end

    context 'with a method chain' do
      let(:source) { 'a, b.c = z' }

      it { is_expected.to eq(%i[a c=]) }
    end
  end

  describe '#expression' do
    include AST::Sexp

    subject { masgn_node.expression }

    context 'with a single RHS value' do
      it { is_expected.to eq(s(:send, nil, :z)) }
    end

    context 'with multiple RHS values' do
      let(:source) { 'x, y = 1, 2' }

      it { is_expected.to eq(s(:array, s(:int, 1), s(:int, 2))) }
    end
  end

  describe '#values' do
    include AST::Sexp

    subject { masgn_node.values }

    context 'when the RHS has a single value' do
      let(:source) { 'x, y = z' }

      it { is_expected.to eq([s(:send, nil, :z)]) }
    end

    context 'when the RHS is an array literal' do
      let(:source) { 'x, y = [z, a]' }

      it { is_expected.to eq([s(:array, s(:send, nil, :z), s(:send, nil, :a))]) }
    end

    context 'when the RHS has a multiple values' do
      let(:source) { 'x, y = u, v' }

      it { is_expected.to eq([s(:send, nil, :u), s(:send, nil, :v)]) }
    end

    context 'when the RHS has a splat' do
      let(:source) { 'x, y = *z' }

      it { is_expected.to eq([s(:splat, s(:send, nil, :z))]) }
    end
  end
end
