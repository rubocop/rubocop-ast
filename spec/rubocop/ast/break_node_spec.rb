# frozen_string_literal: true

require_relative 'wrapped_arguments_node'

RSpec.describe RuboCop::AST::BreakNode do
  it_behaves_like 'wrapped arguments node', 'break'
end
