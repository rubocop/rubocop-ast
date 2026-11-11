# frozen_string_literal: true

require 'parser'

module RuboCop
  module AST
    # `RuboCop::AST::Builder` is an AST builder that is utilized to let `Parser`
    # generate ASTs with {RuboCop::AST::Node}.
    #
    # @example
    #   buffer = Parser::Source::Buffer.new('(string)')
    #   buffer.source = 'puts :foo'
    #
    #   builder = RuboCop::AST::Builder.new
    #   require 'parser/ruby25'
    #   parser = Parser::Ruby25.new(builder)
    #   root_node = parser.parse(buffer)
    class Builder < Parser::Builders::Default
      include BuilderExtensions
    end
  end
end
