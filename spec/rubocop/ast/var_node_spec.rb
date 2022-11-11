# frozen_string_literal: true

RSpec.describe RuboCop::AST::VarNode do
  let(:node) { parse_source(source).node }

  describe '.new' do
    context 'with a `lvar` node' do
      let(:source) { 'x = 1; >>x<<' }

      it { expect(node).to be_a(described_class) }
    end

    context 'with an `ivar` node' do
      let(:source) { '@x' }

      it { expect(node).to be_a(described_class) }
    end

    context 'with an `cvar` node' do
      let(:source) { '@@x' }

      it { expect(node).to be_a(described_class) }
    end

    context 'with an `gvar` node' do
      let(:source) { '$x' }

      it { expect(node).to be_a(described_class) }
    end
  end

  describe '#name' do
    subject { node.name }

    context 'with a `lvar` node' do
      let(:source) { 'x = 1; >>x<<' }

      it { is_expected.to eq(:x) }
    end

    context 'with an `ivar` node' do
      let(:source) { '@x' }

      it { is_expected.to eq(:@x) }
    end

    context 'with an `cvar` node' do
      let(:source) { '@@x' }

      it { is_expected.to eq(:@@x) }
    end

    context 'with an `gvar` node' do
      let(:source) { '$x' }

      it { is_expected.to eq(:$x) }
    end
  end
end
