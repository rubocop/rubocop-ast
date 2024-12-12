# frozen_string_literal: true

RSpec.describe RuboCop::AST::DstrNode do
  subject(:dstr_node) { parse_source(source).ast }

  describe '#value' do
    subject { dstr_node.value }

    context 'with a multiline string' do
      let(:source) do
        <<~RUBY
          'this is a multiline ' \
          'string'
        RUBY
      end

      it { is_expected.to eq('this is a multiline string') }
    end

    context 'with interpolation' do
      let(:source) do
        '"foo #{bar} baz"'
      end

      it { is_expected.to eq('foo #{bar} baz') }
    end

    context 'with implicit concatenation' do
      let(:source) do
        <<~RUBY
          'foo ' 'bar ' 'baz'
        RUBY
      end

      it { is_expected.to eq('foo bar baz') }
    end
  end

  describe '#single_quoted?' do
    context 'with a double-quoted string' do
      let(:source) { '"#{foo}"' }

      it { is_expected.not_to be_single_quoted }
    end

    context 'with a %() delimited string' do
      let(:source) { '%(#{foo})' }

      it { is_expected.not_to be_single_quoted }
    end

    context 'with a %Q() delimited string' do
      let(:source) { '%Q(#{foo})' }

      it { is_expected.not_to be_single_quoted }
    end
  end

  describe '#double_quoted?' do
    context 'with a double-quoted string' do
      let(:source) { '"#{foo}"' }

      it { is_expected.to be_double_quoted }
    end

    context 'with a %() delimited string' do
      let(:source) { '%(#{foo})' }

      it { is_expected.not_to be_double_quoted }
    end

    context 'with a %Q() delimited string' do
      let(:source) { '%Q(#{foo})' }

      it { is_expected.not_to be_double_quoted }
    end
  end

  describe '#percent_literal?' do
    context 'with a quoted string' do
      let(:source) { '"#{foo}"' }

      it { is_expected.not_to be_percent_literal }
      it { is_expected.not_to be_percent_literal(:%) }
      it { is_expected.not_to be_percent_literal(:q) }
      it { is_expected.not_to be_percent_literal(:Q) }
    end

    context 'with a %() delimited string' do
      let(:source) { '%(#{foo})' }

      it { is_expected.to be_percent_literal }
      it { is_expected.to be_percent_literal(:%) }
      it { is_expected.not_to be_percent_literal(:q) }
      it { is_expected.not_to be_percent_literal(:Q) }
    end

    context 'with a %Q() delimited string' do
      let(:source) { '%Q(#{foo})' }

      it { is_expected.to be_percent_literal }
      it { is_expected.not_to be_percent_literal(:%) }
      it { is_expected.not_to be_percent_literal(:q) }
      it { is_expected.to be_percent_literal(:Q) }
    end
  end
end
