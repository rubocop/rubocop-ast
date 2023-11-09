# frozen_string_literal: true

RSpec.describe RuboCop::AST::Procarg0Node, :ruby27 do
  let(:procarg0_node) { parse_source(source).ast.first_argument }

  describe '.new' do
    context 'with a block' do
      let(:source) { 'foo { |x| x }' }

      if RuboCop::AST::Builder.emit_procarg0
        it { expect(procarg0_node).to be_a(described_class) }
      else
        it { expect(procarg0_node).to be_a(RuboCop::AST::ArgNode) }
      end
    end
  end

  describe '#name' do
    subject { procarg0_node.name }

    let(:source) { 'foo { |x| x }' }

    it { is_expected.to eq(:x) }
  end
end
