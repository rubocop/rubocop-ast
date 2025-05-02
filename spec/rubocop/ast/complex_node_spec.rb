# frozen_string_literal: true

RSpec.describe RuboCop::AST::ComplexNode do
  subject(:complex_node) { parse_source(source).ast }

  describe '.new' do
    let(:source) { '+4.2i' }

    it { is_expected.to be_a(described_class) }
  end

  describe '#sign?' do
    subject { complex_node.sign? }

    context 'when explicit positive complex' do
      let(:source) { '+4.2i' }

      it { is_expected.to be(true) }
    end

    context 'when explicit negative complex' do
      let(:source) { '-4.2i' }

      it { is_expected.to be(true) }
    end
  end

  describe '#value' do
    let(:source) { '+4.2i' }

    it { expect(complex_node.value).to eq(+4.2i) }
  end
end
