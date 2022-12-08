# frozen_string_literal: true

require_relative 'helper'

RSpec.describe RuboCop::AST::NodePattern::Parser do
  include_context 'parser'

  describe 'sequences' do
    it 'parses simple sequences properly' do
      expect_parsing(
        s(:sequence, s(:node_type, :int), s(:number, 42)),
        '(int 42)',
        '^        begin
        |       ^ end
        |~~~~~~~~ expression
        | ~~~     expression (node_type)
        |     ~~  expression (number)'
      )
    end

    it 'parses capture vs repetition with correct priority' do
      s_int = s(:capture, s(:node_type, :int))
      s_str = s(:capture, s(:node_type, :str))
      expect_parsing(
        s(:sequence,
          s(:wildcard, '_'),
          s(:repetition, s_int, :*),
          s(:repetition, s(:sequence, s_str), :+)),
        '(_ $int* ($str)+)',
        '^                  begin
        |                ^  end
        |~~~~~~~~~~~~~~~~~  expression
        |   ~~~~~           expression (repetition)
        |       ^           operator (repetition)
        |   ^               operator (repetition.capture)
        |    ~~~            expression (repetition.capture.node_type)'
      )
    end

    it 'parses function calls' do
      expect_parsing(
        s(:function_call, :func, s(:number, 1), s(:number, 2), s(:number, 3)),
        '#func(1, 2, 3)',
        '     ^          begin
        |             ^  end
        |~~~~~           selector
        |      ^         expression (number)'
      )
    end

    it 'expands ... in sequence head deep inside unions' do
      rest = s(:rest, :'...')
      expect_parsing(
        s(:sequence, s(:union,
                       s(:node_type, :a),
                       s(:subsequence, s(:node_type, :b), rest),
                       s(:subsequence, s(:wildcard), rest, s(:node_type, :c)),
                       s(:subsequence, s(:wildcard), s(:capture, rest)))),
        '({a | b ... | ... c | $...})',
        ''
      )
    end

    it 'parses unions of literals as a set' do
      expect_parsing(
        s(:sequence, s(:set, s(:symbol, :a), s(:number, 42), s(:string, 'hello'))),
        '({:a 42 "hello"})',
        ' ^               begin (set)
        |               ^ end (set)
        |     ~~          expression (set/1.number)'
      )
    end

    it 'generates specialized nodes' do
      source_file = Parser::Source::Buffer.new('(spec)', source: '($_)')
      ast = parser.parse(source_file)
      expect(ast.class).to eq RuboCop::AST::NodePattern::Node::Sequence
      expect(ast.child.class).to eq RuboCop::AST::NodePattern::Node::Capture
    end
  end
end
