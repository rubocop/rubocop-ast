# frozen_string_literal: true

RSpec.describe RuboCop::AST::UntilNode do
  subject(:until_node) { parse_source(source).ast }

  describe '.new' do
    context 'with a statement until' do
      let(:source) { 'until foo; bar; end' }

      it { is_expected.to be_a(described_class) }
    end

    context 'with a modifier until' do
      let(:source) { 'begin foo; end until bar' }

      it { is_expected.to be_a(described_class) }
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

  # FIXME: `broken_on: :prism` can be removed when Prism > 0.24.0 will be released.
  describe '#do?', broken_on: :prism do
    context 'with a do keyword' do
      let(:source) { 'until foo do; bar; end' }

      it { is_expected.to be_do }
    end

    context 'without a do keyword' do
      let(:source) { 'until foo; bar; end' }

      it { is_expected.not_to be_do }
    end
  end

  describe '#post_condition_loop?' do
    context 'with a statement until' do
      let(:source) { 'until foo; bar; end' }

      it { is_expected.not_to be_post_condition_loop }
    end

    context 'with a modifier until' do
      let(:source) { 'begin foo; end until bar' }

      it { is_expected.to be_post_condition_loop }
    end
  end

  describe '#loop_keyword?' do
    context 'with a statement until' do
      let(:source) { 'until foo; bar; end' }

      it { is_expected.to be_loop_keyword }
    end

    context 'with a modifier until' do
      let(:source) { 'begin foo; end until bar' }

      it { is_expected.to be_loop_keyword }
    end
  end
end
