# frozen_string_literal: true

RSpec.describe RuboCop::AST::IntNode do
  subject(:int_node) { parse_source(source).ast }

  describe '.new' do
    let(:source) { '42' }

    it { is_expected.to be_a(described_class) }
  end

  describe '#sign?' do
    subject { int_node.sign? }

    context 'explicit positive int' do
      let(:source) { '+42' }

      it { is_expected.to be(true) }
    end

    context 'explicit negative int' do
      let(:source) { '-42' }

      it { is_expected.to be(true) }
    end
  end

  describe '#value' do
    let(:source) do
      '10'
    end

    it { expect(int_node.value).to eq(10) }
  end
end
