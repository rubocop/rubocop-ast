# frozen_string_literal: true

RSpec.describe RuboCop::AST::WhileNode do
  let(:while_node) { parse_source(source).ast }

  describe '.new' do
    context 'with a statement while' do
      let(:source) { 'while foo; bar; end' }

      it { expect(while_node.is_a?(described_class)).to be(true) }
    end

    context 'with a modifier while' do
      let(:source) { 'begin foo; end while bar' }

      it { expect(while_node.is_a?(described_class)).to be(true) }
    end
  end

  describe '#keyword' do
    let(:source) { 'while foo; bar; end' }

    it { expect(while_node.keyword).to eq('while') }
  end

  describe '#inverse_keyword' do
    let(:source) { 'while foo; bar; end' }

    it { expect(while_node.inverse_keyword).to eq('until') }
  end

  describe '#do?' do
    context 'with a do keyword' do
      let(:source) { 'while foo do; bar; end' }

      it { expect(while_node.do?).to be_truthy }
    end

    context 'without a do keyword' do
      let(:source) { 'while foo; bar; end' }

      it { expect(while_node.do?).to be_falsey }
    end
  end

  describe '#post_condition_loop?' do
    context 'with a statement while' do
      let(:source) { 'while foo; bar; end' }

      it { expect(while_node.post_condition_loop?).to be_falsey }
    end

    context 'with a modifier while' do
      let(:source) { 'begin foo; end while bar' }

      it { expect(while_node.post_condition_loop?).to be_truthy }
    end
  end

  describe '#loop_keyword?' do
    context 'with a statement while' do
      let(:source) { 'while foo; bar; end' }

      it { expect(while_node.loop_keyword?).to be_truthy }
    end

    context 'with a modifier while' do
      let(:source) { 'begin foo; end while bar' }

      it { expect(while_node.loop_keyword?).to be_truthy }
    end
  end
end
