# frozen_string_literal: true

RSpec.shared_examples 'wrapped arguments node' do |keyword|
  let(:return_node) { parse_source(source).ast }

  describe '.new' do
    context 'without arguments' do
      let(:source) { keyword }

      it { expect(return_node.is_a?(described_class)).to be(true) }
    end

    context 'with arguments' do
      let(:source) { "#{keyword} :foo" }

      it { expect(return_node.is_a?(described_class)).to be(true) }
    end
  end

  describe '#arguments' do
    context 'with no arguments' do
      let(:source) { keyword }

      it { expect(return_node.arguments.empty?).to be(true) }
    end

    context 'with no arguments and braces' do
      let(:source) { "#{keyword}()" }

      it { expect(return_node.arguments.empty?).to be(true) }
    end

    context 'with a single argument' do
      let(:source) { "#{keyword} :foo" }

      it { expect(return_node.arguments.size).to eq(1) }
    end

    context 'with a single argument and braces' do
      let(:source) { "#{keyword}(:foo)" }

      it { expect(return_node.arguments.size).to eq(1) }
    end

    context 'with a single splat argument' do
      let(:source) { "#{keyword} *baz" }

      it { expect(return_node.arguments.size).to eq(1) }
    end

    context 'with multiple literal arguments' do
      let(:source) { "#{keyword} :foo, :bar" }

      it { expect(return_node.arguments.size).to eq(2) }
    end
  end
end
