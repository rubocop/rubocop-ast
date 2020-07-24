# frozen_string_literal: true

RSpec.describe RuboCop::AST::Ext::Range do
  let(:source) { <<~RUBY }
    [
      1,
      2
    ]
  RUBY

  let(:node) { parse_source(source).ast }

  describe '#line_span' do
    it 'returns the range of lines a range occupies' do
      expect(node.loc.begin.line_span).to eq 1..1
    end

    it 'accepts an `exclude_end` keyword argument' do
      expect(node.loc.expression.line_span(exclude_end: true)).to eq 1...4
    end
  end
end
