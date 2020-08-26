require_relative 'parse_helper'

Failure = Struct.new(:expected, :actual)

module RuboCop::AST::NodePattern::Helper
  include ParseHelper

  def assert_equal(expected, actual, mess = nil)
    expect(actual).to eq(expected), *mess
  end

  def assert(ok, mess = nil)
    expect(ok).to eq(true), *mess
  end

  def expect_parsing(ast, source, source_maps)
    version = '-'
    try_parsing(ast, source, parser, source_maps, version)
  end
end

RSpec.shared_context 'parser' do
  include RuboCop::AST::NodePattern::Helper

  let(:parser) { RuboCop::AST::NodePattern::Parser.new }

  # def it_parses(ast, source, source_maps)
  #   it "parses '#{source}'" do
  #     version = '-'
  #     try_parsing(ast, source, parser, source_maps, version)
  #   end
  # end
end
    # source_file = Parser::Source::Buffer.new('(assert_parses)', source: code)

    # begin
    #   parsed_ast = parser.parse(source_file)
    # rescue => exc
    #   backtrace = exc.backtrace
    #   Exception.instance_method(:initialize).bind(exc).
    #     call("(#{version}) #{exc.message}")
    #   exc.set_backtrace(backtrace)
    #   raise
    # end

    # if ast.nil?
    #   assert_nil parsed_ast, "(#{version}) AST equality"
    #   return
    # end

