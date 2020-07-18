# frozen_string_literal: true

require_relative 'wrapped_arguments_node'

RSpec.describe RuboCop::AST::ReturnNode do
  it_behaves_like 'wrapped arguments node', 'return'
end
