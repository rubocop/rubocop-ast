# frozen_string_literal: true

RSpec.describe RuboCop::AST::FastArray do
  shared_examples 'a fast_array' do
    it { is_expected.to be_frozen }
    it { expect(fast_array.include?(:included)).to be true }
    it { expect(fast_array.include?(:not_included)).to be false }
    it { is_expected.to eq fast_array.dup }

    describe '#to_a' do
      subject { fast_array.to_a }

      it { is_expected.to equal fast_array.to_a }
      it { is_expected.to be_frozen }
      it { is_expected.to include :included }
    end

    describe '#to_set' do
      subject { fast_array.to_set }

      it { is_expected.to equal fast_array.to_set }
      it { is_expected.to be_frozen }
      it { is_expected.to be >= Set[:included] }
    end
  end

  let(:values) { %i[included also_included] }

  describe '.new' do
    subject(:fast_array) { described_class.new(values) }

    it_behaves_like 'a fast_array'

    it 'enforces a single array argument' do
      expect { described_class.new }.to raise_error ArgumentError
      expect { described_class.new(5) }.to raise_error ArgumentError
    end

    it 'has freeze return self' do
      expect(fast_array.freeze).to equal fast_array
    end

    it 'has the right case equality' do
      expect(fast_array).to be === :included # rubocop:disable Style/CaseEquality
    end
  end

  describe '.[]' do
    subject(:fast_array) { described_class[*values] }

    it_behaves_like 'a fast_array'
  end

  describe '()' do
    subject(:fast_array) { FastArray values }

    before { extend RuboCop::AST::FastArray::Function }

    it_behaves_like 'a fast_array'
  end
end
