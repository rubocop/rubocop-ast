# frozen_string_literal: true

RSpec.describe RuboCop::AST::UntilNode do
  let(:until_node) { parse_source(source).ast }

  describe '.new' do
    context 'with a statement until' do
      let(:source) { 'until foo; bar; end' }

      it { expect(until_node.is_a?(described_class)).to be(true) }
    end

    context 'with a modifier until' do
      let(:source) { 'begin foo; end until bar' }

      it { expect(until_node.is_a?(described_class)).to be(true) }
    end
  end

  describe '#keyword' do
    let(:source) { 'until foo; bar; end' }

    it { expect(until_node.keyword).to eq('until') }
  end

  describe '#inverse_keyword' do
    let(:source) { 'until foo; bar; end' }

    it { expect(until_node.inverse_keyword).to eq('while') }
  end

  describe '#do?' do
    context 'with a do keyword' do
      let(:source) { 'until foo do; bar; end' }

      it { expect(until_node.do?).to be_truthy }
    end

    context 'without a do keyword' do
      let(:source) { 'until foo; bar; end' }

      it { expect(until_node.do?).to be_falsey }
    end
  end

  describe '#post_condition_loop?' do
    context 'with a statement until' do
      let(:source) { 'until foo; bar; end' }

      it { expect(until_node.post_condition_loop?).to be_falsey }
    end

    context 'with a modifier until' do
      let(:source) { 'begin foo; end until bar' }

      it { expect(until_node.post_condition_loop?).to be_truthy }
    end
  end

  describe '#loop_keyword?' do
    context 'with a statement until' do
      let(:source) { 'until foo; bar; end' }

      it { expect(until_node.loop_keyword?).to be_truthy }
    end

    context 'with a modifier until' do
      let(:source) { 'begin foo; end until bar' }

      it { expect(until_node.loop_keyword?).to be_truthy }
    end
  end
end
