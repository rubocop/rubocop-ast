# frozen_string_literal: true

RSpec.shared_examples 'wrapped arguments node' do |keyword|
  subject(:return_node) { parse_source(source).ast.body }

  describe '.new' do
    context 'without arguments' do
      let(:source) { "x { #{keyword} }" }

      it { is_expected.to be_a(described_class) }
    end

    context 'with arguments' do
      let(:source) { "x { #{keyword} :foo }" }

      it { is_expected.to be_a(described_class) }
    end
  end

  describe '#arguments' do
    context 'with no arguments' do
      let(:source) { "x { #{keyword} }" }

      it { expect(return_node.arguments).to be_empty }
    end

    context 'with no arguments and braces' do
      let(:source) { "x { #{keyword}() }" }

      it { expect(return_node.arguments).to be_empty }
    end

    context 'with a single argument' do
      let(:source) { "x { #{keyword} :foo }" }

      it { expect(return_node.arguments.size).to eq(1) }
    end

    context 'with a single argument and braces' do
      let(:source) { "x { #{keyword}(:foo) }" }

      it { expect(return_node.arguments.size).to eq(1) }
    end

    context 'with a single splat argument' do
      let(:source) { "x { #{keyword} *baz }" }

      it { expect(return_node.arguments.size).to eq(1) }
    end

    context 'with multiple literal arguments' do
      let(:source) { "x { #{keyword} :foo, :bar }" }

      it { expect(return_node.arguments.size).to eq(2) }
    end
  end
end
