# frozen_string_literal: true

RSpec.describe RuboCop::AST::AsgnNode do
  let(:asgn_node) { parse_source(source).ast }

  describe '.new' do
    context 'with a `lvasgn` node' do
      let(:source) { 'var = value' }

      it { expect(asgn_node).to be_a(described_class) }
    end

    context 'with a `ivasgn` node' do
      let(:source) { '@var = value' }

      it { expect(asgn_node).to be_a(described_class) }
    end

    context 'with a `cvasgn` node' do
      let(:source) { '@@var = value' }

      it { expect(asgn_node).to be_a(described_class) }
    end

    context 'with a `gvasgn` node' do
      let(:source) { '$var = value' }

      it { expect(asgn_node).to be_a(described_class) }
    end
  end

  describe '#name' do
    subject { asgn_node.name }

    context 'with a `lvasgn` node' do
      let(:source) { 'var = value' }

      it { is_expected.to eq(:var) }
    end

    context 'with a `ivasgn` node' do
      let(:source) { '@var = value' }

      it { is_expected.to eq(:@var) }
    end

    context 'with a `cvasgn` node' do
      let(:source) { '@@var = value' }

      it { is_expected.to eq(:@@var) }
    end

    context 'with a `gvasgn` node' do
      let(:source) { '$var = value' }

      it { is_expected.to eq(:$var) }
    end
  end

  describe '#expression' do
    include AST::Sexp

    subject { asgn_node.expression }

    context 'with a `lvasgn` node' do
      let(:source) { 'var = value' }

      it { is_expected.to eq(s(:send, nil, :value)) }
    end

    context 'with a `ivasgn` node' do
      let(:source) { '@var = value' }

      it { is_expected.to eq(s(:send, nil, :value)) }
    end

    context 'with a `cvasgn` node' do
      let(:source) { '@@var = value' }

      it { is_expected.to eq(s(:send, nil, :value)) }
    end

    context 'with a `gvasgn` node' do
      let(:source) { '$var = value' }

      it { is_expected.to eq(s(:send, nil, :value)) }
    end
  end
end
