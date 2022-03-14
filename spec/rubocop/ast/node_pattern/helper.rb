# frozen_string_literal: true

require_relative 'parse_helper'

Failure = Struct.new(:expected, :actual)

module NodePatternHelper
  include ParseHelper

  def assert_equal(expected, actual, mess = nil)
    expect(actual).to eq(expected), *mess
  end

  def assert(test, mess = nil)
    expect(test).to be(true), *mess
  end

  def expect_parsing(ast, source, source_maps)
    version = '-'
    try_parsing(ast, source, parser, source_maps, version)
  end
end

RSpec.shared_context 'parser' do
  include NodePatternHelper

  let(:parser) { RuboCop::AST::NodePattern::Parser::WithMeta.new }
end
