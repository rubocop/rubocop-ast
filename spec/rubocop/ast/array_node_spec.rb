# frozen_string_literal: true

RSpec.describe RuboCop::AST::ArrayNode do
  subject(:array_node) { parse_source(source).ast }

  let(:array_pattern_source) { '[foo, bar]' }
  let(:array_pattern_node) do
    source = <<~RUBY
      case foo
        in >>#{array_pattern_source}<<
      end
    RUBY
    parse_source(source).node
  end

  describe '.new' do
    context 'with an array literal' do
      let(:source) { '[]' }

      it { is_expected.to be_a(described_class) }
    end

    context 'with an `array-pattern`', :ruby27 do
      subject { array_pattern_node }

      it { is_expected.to be_a(described_class) }
    end
  end

  describe '#values' do
    context 'with an empty array' do
      let(:source) { '[]' }

      it { expect(array_node.values).to be_empty }
    end

    context 'with an array of literals' do
      let(:source) { '[1, 2, 3]' }

      it { expect(array_node.values.size).to eq(3) }
      it { expect(array_node.values).to all(be_literal) }
    end

    context 'with an array of variables' do
      let(:source) { '[foo, bar]' }

      it { expect(array_node.values.size).to eq(2) }
      it { expect(array_node.values).to all(be_send_type) }
    end

    context 'with an `array-pattern`', :ruby27 do
      it { expect(array_pattern_node.values.size).to eq(2) }
      it { expect(array_pattern_node.values).to all(be_match_var_type) }
    end
  end

  describe '#each_value' do
    let(:source) { '[1, 2, 3]' }

    context 'with block' do
      it { expect(array_node.each_value { nil }).to be_a(described_class) }

      it do
        ret = []
        array_node.each_value { |i| ret << i.to_s }

        expect(ret).to eq(['(int 1)', '(int 2)', '(int 3)'])
      end
    end

    context 'without block' do
      it { expect(array_node.each_value).to be_a(Enumerator) }
    end
  end

  describe '#square_brackets?' do
    context 'with square brackets' do
      let(:source) { '[1, 2, 3]' }

      it { is_expected.to be_square_brackets }
    end

    context 'with a percent literal' do
      let(:source) { '%w(foo bar)' }

      it { is_expected.not_to be_square_brackets }
    end

    context 'with an `array-pattern`', :ruby27 do
      subject { array_pattern_node }

      context 'with square brackets' do
        it { is_expected.to be_square_brackets }
      end

      context 'with no brackets' do
        let(:array_pattern_source) { 'foo, bar' }

        it { is_expected.not_to be_square_brackets }
      end
    end
  end

  describe '#percent_literal?' do
    context 'with square brackets' do
      let(:source) { '[1, 2, 3]' }

      it { is_expected.not_to be_percent_literal }
      it { is_expected.not_to be_percent_literal(:string) }
      it { is_expected.not_to be_percent_literal(:symbol) }
    end

    context 'with a string percent literal' do
      let(:source) { '%w(foo bar)' }

      it { is_expected.to be_percent_literal }
      it { is_expected.to be_percent_literal(:string) }
      it { is_expected.not_to be_percent_literal(:symbol) }
    end

    context 'with a symbol percent literal' do
      let(:source) { '%i(foo bar)' }

      it { is_expected.to be_percent_literal }
      it { is_expected.not_to be_percent_literal(:string) }
      it { is_expected.to be_percent_literal(:symbol) }
    end

    context 'with an `array-pattern`', :ruby27 do
      subject { array_pattern_node }

      context 'with square brackets' do
        it { is_expected.not_to be_percent_literal }
        it { is_expected.not_to be_percent_literal(:string) }
        it { is_expected.not_to be_percent_literal(:symbol) }
      end

      context 'with no brackets' do
        let(:array_pattern_source) { 'foo, bar' }

        it { is_expected.not_to be_percent_literal }
        it { is_expected.not_to be_percent_literal(:string) }
        it { is_expected.not_to be_percent_literal(:symbol) }
      end
    end
  end

  describe '#bracketed?' do
    context 'with square brackets' do
      let(:source) { '[1, 2, 3]' }

      it { is_expected.to be_bracketed }
    end

    context 'with a percent literal' do
      let(:source) { '%w(foo bar)' }

      it { is_expected.to be_bracketed }
    end

    context 'unbracketed' do
      let(:array_node) do
        parse_source('foo = >>1, 2, 3<<').node
      end

      it { expect(array_node).not_to be_bracketed }
    end

    context 'with an `array-pattern`', :ruby27 do
      subject { array_pattern_node }

      context 'with square brackets' do
        it { is_expected.to be_bracketed }
      end

      context 'with no brackets' do
        let(:array_pattern_source) { 'foo, bar' }

        it { is_expected.not_to be_bracketed }
      end
    end
  end
end
