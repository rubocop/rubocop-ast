# frozen_string_literal: true

RSpec.describe RuboCop::AST::RangeNode do
  subject(:range_node) { parse_source(source).ast }

  describe '.new' do
    context 'with an inclusive range' do
      let(:source) do
        '1..2'
      end

      it { is_expected.to be_a(described_class) }
      it { is_expected.to be_range_type }
    end

    context 'with an exclusive range' do
      let(:source) do
        '1...2'
      end

      it { is_expected.to be_a(described_class) }
      it { is_expected.to be_range_type }
    end

    context 'with an infinite range', :ruby26 do
      let(:source) do
        '1..'
      end

      it { is_expected.to be_a(described_class) }
      it { is_expected.to be_range_type }
    end

    context 'with a beignless range', :ruby27 do
      let(:source) do
        '..42'
      end

      it { is_expected.to be_a(described_class) }
      it { is_expected.to be_range_type }
    end
  end
end
