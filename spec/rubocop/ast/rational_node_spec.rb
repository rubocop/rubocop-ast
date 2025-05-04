# frozen_string_literal: true

RSpec.describe RuboCop::AST::RationalNode do
  subject(:rational_node) { parse_source(source).ast }

  describe '.new' do
    let(:source) { '0.2r' }

    it { is_expected.to be_a(described_class) }
  end

  describe '#sign?' do
    subject { rational_node.sign? }

    context 'when explicit positive rational' do
      let(:source) { '+0.2r' }

      it { is_expected.to be(true) }
    end

    context 'when explicit negative rational' do
      let(:source) { '-0.2r' }

      it { is_expected.to be(true) }
    end
  end

  describe '#value' do
    let(:source) do
      '0.4r'
    end

    it { expect(rational_node.value).to eq(0.4r) }
  end
end
