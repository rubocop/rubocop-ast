# frozen_string_literal: true

RSpec.shared_context 'parser' do
  let(:parser) { RuboCop::AST::NodePattern::Parser.new }
end
