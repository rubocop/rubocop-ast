# frozen_string_literal: true

RSpec.describe RuboCop::AST::DefinedNode do
  subject(:defined_node) { parse_source(source).ast }

  describe '.new' do
    context 'with a defined? node' do
      let(:source) { 'defined? :foo' }

      it { is_expected.to be_a(described_class) }
    end
  end

  describe '#receiver' do
    let(:source) { 'defined? :foo' }

    it { expect(defined_node.receiver).to be_nil }
  end

  describe '#method_name' do
    let(:source) { 'defined? :foo' }

    it { expect(defined_node.method_name).to eq(:defined?) }
  end

  describe '#arguments' do
    let(:source) { 'defined? :foo' }

    it { expect(defined_node.arguments.size).to eq(1) }
    it { expect(defined_node.arguments).to all(be_sym_type) }
  end
end
