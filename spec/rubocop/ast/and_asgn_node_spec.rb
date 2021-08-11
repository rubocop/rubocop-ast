# frozen_string_literal: true

RSpec.describe RuboCop::AST::AndAsgnNode do
  let(:or_asgn_node) { parse_source(source).ast }
  let(:source) { 'var &&= value' }

  describe '.new' do
    it { expect(or_asgn_node).to be_a(described_class) }
  end

  describe '#assignment_node' do
    subject { or_asgn_node.assignment_node }

    it { is_expected.to be_a(RuboCop::AST::AsgnNode) }
  end

  describe '#name' do
    subject { or_asgn_node.name }

    it { is_expected.to eq(:var) }
  end

  describe '#operator' do
    subject { or_asgn_node.operator }

    it { is_expected.to eq(:'&&') }
  end

  describe '#expression' do
    include AST::Sexp

    subject { or_asgn_node.expression }

    it { is_expected.to eq(s(:send, nil, :value)) }
  end
end
