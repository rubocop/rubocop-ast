# frozen_string_literal: true

RSpec.describe RuboCop::AST::CasgnNode do
  let(:casgn_node) { parse_source(source).ast }

  describe '.new' do
    context 'with a `casgn` node' do
      let(:source) { 'VAR = value' }

      it { expect(casgn_node).to be_a(described_class) }
    end
  end

  describe '#namespace' do
    include AST::Sexp

    subject { casgn_node.namespace }

    context 'when there is no parent' do
      let(:source) { 'VAR = value' }

      it { is_expected.to eq(nil) }
    end

    context 'when the parent is a `cbase`' do
      let(:source) { '::VAR = value' }

      it { is_expected.to eq(s(:cbase)) }
    end

    context 'when the parent is a `const`' do
      let(:source) { 'FOO::VAR = value' }

      it { is_expected.to eq(s(:const, nil, :FOO)) }
    end
  end

  describe '#name' do
    subject { casgn_node.name }

    let(:source) { 'VAR = value' }

    it { is_expected.to eq(:VAR) }
  end

  describe '#expression' do
    include AST::Sexp

    subject { casgn_node.expression }

    let(:source) { 'VAR = value' }

    it { is_expected.to eq(s(:send, nil, :value)) }
  end
end
