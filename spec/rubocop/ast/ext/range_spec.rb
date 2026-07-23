# frozen_string_literal: true

RSpec.describe RuboCop::AST::Ext::Range do
  subject(:node) { parse_source(source).ast }

  let(:source) { <<~RUBY }
    [
      1,
      2
    ]
  RUBY

  describe '#line_span' do
    it 'returns the range of lines a range occupies' do
      expect(node.loc.begin.line_span).to eq 1..1
    end

    it 'accepts an `exclude_end` keyword argument' do
      expect(node.source_range.line_span(exclude_end: true)).to eq 1...4
    end
  end

  describe '#same_line?' do
    let(:source) { <<~RUBY }
      foo(1,
          2) # comment
      bar(3)
    RUBY

    let(:processed_source) { parse_source(source) }
    let(:foo_node) { processed_source.ast.children.first }
    let(:bar_node) { processed_source.ast.children.last }

    it 'is true for a range on the same line' do
      expect(foo_node.source_range).to be_same_line(foo_node.loc.selector)
    end

    it 'is false for a range on another line' do
      expect(foo_node.source_range).not_to be_same_line(foo_node.loc.end)
    end

    it 'accepts a node' do
      expect(foo_node.source_range).not_to be_same_line(bar_node)
      expect(bar_node.source_range).to be_same_line(bar_node)
    end

    it 'accepts a token' do
      first_token = processed_source.tokens.first
      expect(foo_node.source_range).to be_same_line(first_token)
    end

    it 'accepts a comment' do
      comment = processed_source.comments.first
      expect(foo_node.loc.end).to be_same_line(comment)
    end

    it 'compares by the line the range starts on' do
      expect(foo_node.source_range).not_to be_same_line(foo_node.source_range.end)
    end
  end

  describe '#begins_its_line?' do
    let(:source) { <<~RUBY }
      foo
        .bar(1,
             2)
    RUBY

    let(:send_node) { parse_source(source).ast }

    it 'is true for a range preceded only by whitespace' do
      expect(send_node.loc.selector.adjust(begin_pos: -1)).to be_begins_its_line
    end

    it 'is false for a range preceded by code' do
      expect(send_node.loc.selector).not_to be_begins_its_line
    end

    it 'is true for a range at the very start of a line' do
      expect(send_node.source_range).to be_begins_its_line
    end

    context 'with indentation deeper than the cached regexps' do
      let(:source) { "#{' ' * 60}foo\n" }

      it 'is true for a range preceded only by whitespace' do
        expect(send_node.source_range).to be_begins_its_line
      end
    end
  end
end
