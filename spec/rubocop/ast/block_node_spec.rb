# frozen_string_literal: true

RSpec.describe RuboCop::AST::BlockNode do
  subject(:block_node) { parse_source(source).ast }

  describe '.new' do
    let(:source) { 'foo { |q| bar(q) }' }

    it { is_expected.to be_a(described_class) }
  end

  describe '#arguments' do
    context 'with no arguments' do
      let(:source) { 'foo { bar }' }

      it { expect(block_node.arguments).to be_empty }
    end

    context 'with a single literal argument' do
      let(:source) { 'foo { |q| bar(q) }' }

      it { expect(block_node.arguments.size).to eq(1) }
    end

    context 'with a single splat argument' do
      let(:source) { 'foo { |*q| bar(q) }' }

      it { expect(block_node.arguments.size).to eq(1) }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'foo { |q, *z| bar(q, z) }' }

      it { expect(block_node.arguments.size).to eq(2) }
    end

    context '>= Ruby 2.7', :ruby27 do
      context 'using numbered parameters' do
        let(:source) { 'foo { _1 }' }

        it { expect(block_node.arguments).to be_empty }
      end
    end
  end

  describe '#arguments?' do
    context 'with no arguments' do
      let(:source) { 'foo { bar }' }

      it { is_expected.not_to be_arguments }
    end

    context 'with a single argument' do
      let(:source) { 'foo { |q| bar(q) }' }

      it { is_expected.to be_arguments }
    end

    context 'with a single splat argument' do
      let(:source) { 'foo { |*q| bar(q) }' }

      it { is_expected.to be_arguments }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'foo { |q, *z| bar(q, z) }' }

      it { is_expected.to be_arguments }
    end

    context '>= Ruby 2.7', :ruby27 do
      context 'using numbered parameters' do
        let(:source) { 'foo { _1 }' }

        it { is_expected.not_to be_arguments }
      end
    end
  end

  describe '#braces?' do
    context 'when enclosed in braces' do
      let(:source) { 'foo { bar }' }

      it { is_expected.to be_braces }
    end

    context 'when enclosed in do-end keywords' do
      let(:source) do
        ['foo do',
         '  bar',
         'end'].join("\n")
      end

      it { is_expected.not_to be_braces }
    end
  end

  describe '#keywords?' do
    context 'when enclosed in braces' do
      let(:source) { 'foo { bar }' }

      it { is_expected.not_to be_keywords }
    end

    context 'when enclosed in do-end keywords' do
      let(:source) do
        ['foo do',
         '  bar',
         'end'].join("\n")
      end

      it { is_expected.to be_keywords }
    end
  end

  describe '#lambda?' do
    context 'when block belongs to a stabby lambda' do
      let(:source) { '-> { bar }' }

      it { is_expected.to be_lambda }
    end

    context 'when block belongs to a method lambda' do
      let(:source) { 'lambda { bar }' }

      it { is_expected.to be_lambda }
    end

    context 'when block belongs to a non-lambda method' do
      let(:source) { 'foo { bar }' }

      it { is_expected.not_to be_lambda }
    end
  end

  describe '#delimiters' do
    context 'when enclosed in braces' do
      let(:source) { 'foo { bar }' }

      it { expect(block_node.delimiters).to eq(%w[{ }]) }
    end

    context 'when enclosed in do-end keywords' do
      let(:source) do
        ['foo do',
         '  bar',
         'end'].join("\n")
      end

      it { expect(block_node.delimiters).to eq(%w[do end]) }
    end
  end

  describe '#opening_delimiter' do
    context 'when enclosed in braces' do
      let(:source) { 'foo { bar }' }

      it { expect(block_node.opening_delimiter).to eq('{') }
    end

    context 'when enclosed in do-end keywords' do
      let(:source) do
        ['foo do',
         '  bar',
         'end'].join("\n")
      end

      it { expect(block_node.opening_delimiter).to eq('do') }
    end
  end

  describe '#closing_delimiter' do
    context 'when enclosed in braces' do
      let(:source) { 'foo { bar }' }

      it { expect(block_node.closing_delimiter).to eq('}') }
    end

    context 'when enclosed in do-end keywords' do
      let(:source) do
        ['foo do',
         '  bar',
         'end'].join("\n")
      end

      it { expect(block_node.closing_delimiter).to eq('end') }
    end
  end

  describe '#single_line?' do
    context 'when block is on a single line' do
      let(:source) { 'foo { bar }' }

      it { is_expected.to be_single_line }
    end

    context 'when block is on several lines' do
      let(:source) do
        ['foo do',
         '  bar',
         'end'].join("\n")
      end

      it { is_expected.not_to be_single_line }
    end
  end

  describe '#multiline?' do
    context 'when block is on a single line' do
      let(:source) { 'foo { bar }' }

      it { is_expected.not_to be_multiline }
    end

    context 'when block is on several lines' do
      let(:source) do
        ['foo do',
         '  bar',
         'end'].join("\n")
      end

      it { is_expected.to be_multiline }
    end
  end

  describe '#void_context?' do
    context 'when block method is each' do
      let(:source) { 'each { bar }' }

      it { is_expected.to be_void_context }
    end

    context 'when block method is tap' do
      let(:source) { 'tap { bar }' }

      it { is_expected.to be_void_context }
    end

    context 'when block method is not each' do
      let(:source) { 'map { bar }' }

      it { is_expected.not_to be_void_context }
    end
  end
end
