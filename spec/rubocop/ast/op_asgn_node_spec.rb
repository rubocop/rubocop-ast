# frozen_string_literal: true

RSpec.describe RuboCop::AST::OpAsgnNode do
  let(:parsed_source) { parse_source(source) }
  let(:op_asgn_node) { parsed_source.ast }

  describe '.new' do
    context 'with an `op_asgn_node` node' do
      let(:source) { 'var += value' }

      it { expect(op_asgn_node).to be_a(described_class) }
    end
  end

  describe '#assignment_node' do
    subject { op_asgn_node.assignment_node }

    let(:source) { 'var += value' }
    let(:node) { parsed_source.node }

    it { is_expected.to be_a(RuboCop::AST::AsgnNode) }

    context 'when the LHS is a `send` node' do
      let(:source) { '>> foo.var << += value' }

      it { is_expected.to eq(node) }
    end

    context 'when the LHS is a `csend` node' do
      let(:source) { '>> foo&.var << += value' }

      it { is_expected.to eq(node) }
    end
  end

  describe '#name' do
    subject { op_asgn_node.name }

    let(:source) { 'var += value' }

    it { is_expected.to eq(:var) }

    context 'when the LHS is a `send` node' do
      let(:source) { 'foo.var += value' }

      it { is_expected.to eq(:var) }
    end

    context 'when the LHS is a `csend` node' do
      let(:source) { 'foo&.var += value' }

      it { is_expected.to eq(:var) }
    end
  end

  describe '#operator' do
    subject { op_asgn_node.operator }

    context 'with +=' do
      let(:source) { 'var += value' }

      it { is_expected.to eq(:+) }
    end

    context 'with -=' do
      let(:source) { 'var -= value' }

      it { is_expected.to eq(:-) }
    end

    context 'with *=' do
      let(:source) { 'var *= value' }

      it { is_expected.to eq(:*) }
    end

    context 'with /=' do
      let(:source) { 'var /= value' }

      it { is_expected.to eq(:/) }
    end

    context 'with &=' do
      let(:source) { 'var &= value' }

      it { is_expected.to eq(:&) }
    end

    context 'with |=' do
      let(:source) { 'var |= value' }

      it { is_expected.to eq(:|) }
    end

    context 'with %=' do
      let(:source) { 'var %= value' }

      it { is_expected.to eq(:%) }
    end

    context 'with **=' do
      let(:source) { 'var **= value' }

      it { is_expected.to eq(:**) }
    end
  end

  describe '#expression' do
    include AST::Sexp

    subject { op_asgn_node.expression }

    let(:source) { 'var += value' }

    it { is_expected.to eq(s(:send, nil, :value)) }
  end
end
