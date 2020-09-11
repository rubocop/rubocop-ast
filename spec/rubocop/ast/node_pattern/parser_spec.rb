# frozen_string_literal: true

require_relative 'helper'

RSpec.describe RuboCop::AST::NodePattern::Parser do
  include_context 'parser'

  describe 'sequences' do
    it 'generates specialized nodes' do
      ast = parser.parse('($_)')
      expect(ast.class).to eq ::RuboCop::AST::NodePattern::Node::Sequence
      expect(ast.child.class).to eq ::RuboCop::AST::NodePattern::Node::Capture
    end
  end
end
