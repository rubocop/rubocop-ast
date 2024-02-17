# frozen_string_literal: true

RSpec.describe RuboCop::AST::WhileNode do
  subject(:while_node) { parse_source(source).ast }

  describe '.new' do
    context 'with a statement while' do
      let(:source) { 'while foo; bar; end' }

      it { is_expected.to be_a(described_class) }
    end

    context 'with a modifier while' do
      let(:source) { 'begin foo; end while bar' }

      it { is_expected.to be_a(described_class) }
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
    # FIXME: `broken_on: :prism` can be removed when Prism > 0.24.0 will be released.
    context 'with a do keyword', broken_on: :prism do
      let(:source) { 'while foo do; bar; end' }

      it { is_expected.to be_do }
    end

    context 'without a do keyword' do
      let(:source) { 'while foo; bar; end' }

      it { is_expected.not_to be_do }
    end
  end

  describe '#post_condition_loop?' do
    context 'with a statement while' do
      let(:source) { 'while foo; bar; end' }

      it { is_expected.not_to be_post_condition_loop }
    end

    context 'with a modifier while' do
      let(:source) { 'begin foo; end while bar' }

      it { is_expected.to be_post_condition_loop }
    end
  end

  describe '#loop_keyword?' do
    context 'with a statement while' do
      let(:source) { 'while foo; bar; end' }

      it { is_expected.to be_loop_keyword }
    end

    context 'with a modifier while' do
      let(:source) { 'begin foo; end while bar' }

      it { is_expected.to be_loop_keyword }
    end
  end
end
