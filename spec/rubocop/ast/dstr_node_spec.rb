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
end
