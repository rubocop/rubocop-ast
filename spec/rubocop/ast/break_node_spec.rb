# frozen_string_literal: true

RSpec.describe RuboCop::AST::BreakNode do
  let(:break_node) { parse_source(source).ast }

  describe '.new' do
    context 'with a break node' do
      let(:source) { 'break' }

      it { expect(break_node.is_a?(described_class)).to be(true) }
    end
  end

  describe '#arguments' do
    let(:source) { 'break 1, 2' }

    it { expect(break_node.arguments.size).to eq 2 }
  end
end
