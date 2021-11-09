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

    context 'with nested assignment on LHS' do
      let(:source) { 'a, b[c+=1] = z' }

      it { is_expected.to eq([:a, 'b[c+=1]']) }
    end

    context 'with a method chain on LHS' do
      let(:source) { 'a, b.c = z' }

      it { is_expected.to eq([:a, 'b.c']) }
    end
  end

  describe '#expression' do
    include AST::Sexp

    subject { masgn_node.expression }

    context 'with variables' do
      it { is_expected.to eq(s(:send, nil, :z)) }
    end

    context 'with a LHS splat' do
      let(:source) { 'x, *y = z' }

      it { is_expected.to eq(s(:send, nil, :z)) }
    end

    context 'with multiple RHS values' do
      let(:source) { 'x, y = 1, 2' }

      it { is_expected.to eq(s(:array, s(:int, 1), s(:int, 2))) }
    end

    context 'with an RHS splat' do
      let(:source) { 'x, y = *z' }

      it { is_expected.to eq(s(:array, s(:splat, s(:send, nil, :z)))) }
    end

    context 'with assignment on RHS' do
      let(:source) { 'x, y = 1, z+=2' }

      it { is_expected.to eq(s(:array, s(:int, 1), s(:op_asgn, s(:lvasgn, :z), :+, s(:int, 2)))) }
    end
  end

  describe '#values' do
    include AST::Sexp

    subject { masgn_node.values }

    context 'when the RHS has a single value' do
      let(:source) { 'x, y = z' }

      it { is_expected.to eq([s(:send, nil, :z)]) }
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

  describe '#array?' do
    subject { masgn_node.array? }

    context 'when the RHS has a single value' do
      let(:source) { 'x, y = z' }

      it { is_expected.to eq(false) }
    end

    context 'when the RHS has a multiple values' do
      let(:source) { 'x, y = u, v' }

      it { is_expected.to eq(true) }
    end

    context 'when the RHS has a splat' do
      let(:source) { 'x, y = *z' }

      it { is_expected.to eq(true) }
    end
  end
end
