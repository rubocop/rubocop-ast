# frozen_string_literal: true

RSpec.describe RuboCop::AST::ProcessedSource do
  subject(:processed_source) do
    described_class.new(source, ruby_version, path, parser_engine: parser_engine)
  end

  let(:source) { <<~RUBY }
    # an awesome method
    def some_method
      puts 'foo'
    end
    some_method
  RUBY
  let(:ast) { processed_source.ast }
  let(:path) { 'ast/and_node_spec.rb' }

  shared_context 'invalid encoding source' do
    let(:source) { "# \xf9" }
  end

  describe '#initialize' do
    context 'when parsing non UTF-8 frozen string' do
      let(:source) { (+'true').force_encoding(Encoding::ASCII_8BIT).freeze }

      it 'returns an instance of ProcessedSource' do
        is_expected.to be_a(described_class)
      end
    end

    context 'when parsing code with an invalid encoding comment' do
      let(:source) { '# encoding: foobar' }

      it 'returns a parser error' do
        expect(processed_source.parser_error).to be_a(Parser::UnknownEncodingInMagicComment)
        expect(processed_source.parser_error.message)
          .to include('unknown encoding name - foobar')
      end
    end

    shared_examples 'invalid parser_engine' do
      it 'raises ArgumentError' do
        expect { processed_source }.to raise_error(ArgumentError) do |e|
          expected =  'The keyword argument `parser_engine` accepts `parser_whitequark` ' \
                      "or `parser_prism`, but `#{parser_engine}` was passed."
          expect(e.message).to eq(expected)
        end
      end
    end

    context 'when using an invalid `parser_engine` symbol argument' do
      let(:parser_engine) { :unknown_parser_engine }

      it_behaves_like 'invalid parser_engine'
    end

    context 'when using an invalid `parser_engine` string argument' do
      let(:parser_engine) { 'unknown_parser_engine' }

      it_behaves_like 'invalid parser_engine'
    end
  end

  describe '.from_file' do
    describe 'when the file exists' do
      around do |example|
        org_pwd = Dir.pwd
        Dir.chdir("#{__dir__}/..")
        example.run
        Dir.chdir(org_pwd)
      end

      let(:processed_source) do
        described_class.from_file(path, ruby_version, parser_engine: parser_engine)
      end

      it 'returns an instance of ProcessedSource' do
        is_expected.to be_a(described_class)
      end

      it "sets the file path to the instance's #path" do
        expect(processed_source.path).to eq(path)
      end
    end

    it 'raises a Errno::ENOENT when the file does not exist' do
      expect do
        described_class.from_file('foo', ruby_version)
      end.to raise_error(Errno::ENOENT)
    end
  end

  describe '#path' do
    it 'is the path passed to .new' do
      expect(processed_source.path).to eq(path)
    end
  end

  describe '#buffer' do
    it 'is a source buffer' do
      expect(processed_source.buffer).to be_a(Parser::Source::Buffer)
    end
  end

  describe '#ast' do
    it 'is the root node of AST' do
      expect(processed_source.ast).to be_a(RuboCop::AST::Node)
    end
  end

  describe '#comments' do
    it 'is an array of comments' do
      expect(processed_source.comments).to be_a(Array)
      expect(
        processed_source.comments.first
      ).to be_a(Parser::Source::Comment)
    end

    context 'when the source is invalid' do
      include_context 'invalid encoding source'

      it 'returns []' do
        expect(processed_source.comments).to eq []
      end
    end
  end

  describe '#tokens' do
    it 'has an array of tokens' do
      expect(processed_source.tokens).to be_a(Array)
      expect(processed_source.tokens.first).to be_a(RuboCop::AST::Token)
    end
  end

  describe '#parser_error' do
    context 'when the source was properly parsed' do
      it 'is nil' do
        expect(processed_source.parser_error).to be_nil
      end
    end

    context 'when the source lacks encoding comment and is really utf-8 ' \
            'encoded but has been read as US-ASCII' do
      let(:source) do
        # When files are read into RuboCop, the encoding of source code
        # lacking an encoding comment will default to the external encoding,
        # which could for example be US-ASCII if the LC_ALL environment
        # variable is set to "C".
        (+'号码 = 3').force_encoding('US-ASCII')
      end

      it 'is nil' do
        # ProcessedSource#parse sets UTF-8 as default encoding, so no error.
        expect(processed_source.parser_error).to be_nil
      end
    end

    context 'when the source could not be parsed due to encoding error' do
      include_context 'invalid encoding source'

      it 'returns the error' do
        expect(processed_source.parser_error).to be_a(Exception)
        expect(processed_source.parser_error.message)
          .to include('invalid byte sequence')
      end
    end
  end

  describe '#lines' do
    it 'is an array' do
      expect(processed_source.lines).to be_a(Array)
    end

    it 'has same number of elements as line count' do
      # Since the source has a trailing newline, there is a final empty line
      expect(processed_source.lines.size).to eq(6)
    end

    it 'contains lines as string without linefeed' do
      first_line = processed_source.lines.first
      expect(first_line).to eq('# an awesome method')
    end
  end

  describe '#[]' do
    context 'when an index is passed' do
      it 'returns the line' do
        expect(processed_source[3]).to eq('end')
      end
    end

    context 'when a range is passed' do
      it 'returns the array of lines' do
        expect(processed_source[3..4]).to eq(%w[end some_method])
      end
    end

    context 'when start index and length are passed' do
      it 'returns the array of lines' do
        expect(processed_source[3, 2]).to eq(%w[end some_method])
      end
    end
  end

  describe 'valid_syntax?' do
    subject { processed_source.valid_syntax? }

    context 'when the source is completely valid' do
      let(:source) { 'def valid_code; end' }

      it 'returns true' do
        expect(processed_source.diagnostics).to be_empty
        expect(processed_source).to be_valid_syntax
      end
    end

    context 'when the source is invalid' do
      let(:source) { 'def invalid_code; en' }

      it 'returns false' do
        expect(processed_source).not_to be_valid_syntax
      end
    end

    # FIXME: `broken_on: :prism` can be removed when
    # https://github.com/ruby/prism/issues/2454 will be released.
    context 'when the source is valid but has some warning diagnostics', broken_on: :prism do
      let(:source) { 'do_something *array' }

      it 'returns true' do
        expect(processed_source.diagnostics).not_to be_empty
        expect(processed_source.diagnostics.first.level).to eq(:warning)
        expect(processed_source).to be_valid_syntax
      end
    end

    context 'when the source could not be parsed due to encoding error' do
      include_context 'invalid encoding source'

      it 'returns false' do
        expect(processed_source).not_to be_valid_syntax
      end
    end

    # https://github.com/whitequark/parser/issues/283
    context 'when the source itself is valid encoding but includes strange ' \
            'encoding literals that are accepted by MRI' do
      let(:source) do
        'p "\xff"'
      end

      it 'returns true' do
        expect(processed_source.diagnostics).to be_empty
        expect(processed_source).to be_valid_syntax
      end
    end

    context 'when a line starts with an integer literal' do
      let(:source) { '1 + 1' }

      # regression test
      it 'tokenizes the source correctly' do
        expect(processed_source.tokens[0].text).to eq '1'
      end
    end
  end

  context 'with heavily commented source' do
    let(:source) { <<~RUBY }
      # comment one
      [ 1,
        { a: 2,
          b: 3 # comment two
        }
      ]
    RUBY

    describe '#each_comment' do
      it 'yields all comments' do
        comments = []

        processed_source.each_comment do |item|
          expect(item).to be_a(Parser::Source::Comment)
          comments << item
        end

        expect(comments.size).to eq 2
      end
    end

    describe '#find_comment' do
      it 'yields correct comment' do
        comment = processed_source.find_comment do |item|
          item.text == '# comment two'
        end

        expect(comment.text).to eq '# comment two'
      end

      it 'yields nil when there is no match' do
        comment = processed_source.find_comment do |item|
          item.text == '# comment four'
        end

        expect(comment).to be_nil
      end
    end

    describe '#comment_at_line' do
      it 'returns the comment at the given line number' do
        expect(processed_source.comment_at_line(1).text).to eq '# comment one'
        expect(processed_source.comment_at_line(4).text).to eq '# comment two'
      end

      it 'returns nil if line has no comment' do
        expect(processed_source.comment_at_line(3)).to be_nil
      end
    end

    describe '#each_comment_in_lines' do
      it 'yields the comments' do
        enum = processed_source.each_comment_in_lines(1..4)
        expect(enum).to be_a(Enumerable)
        expect(enum.to_a).to eq processed_source.comments
        expect(processed_source.each_comment_in_lines(2..5).map(&:text)).to eq ['# comment two']
      end
    end

    describe '#line_with_comment?' do
      it 'returns true for lines with comments' do
        expect(processed_source).to be_line_with_comment(1)
        expect(processed_source).to be_line_with_comment(4)
      end

      it 'returns false for lines without comments' do
        expect(processed_source).not_to be_line_with_comment(2)
        expect(processed_source).not_to be_line_with_comment(5)
      end
    end

    describe '#contains_comment?' do
      subject(:commented) { processed_source.contains_comment?(range) }

      let(:array) { ast }
      let(:hash) { array.children[1] }

      context 'provided source_range on line without comment' do
        let(:range) { hash.pairs.first.source_range }

        it { is_expected.to be false }
      end

      context 'provided source_range on comment line' do
        let(:range) { processed_source.find_token(&:comment?).pos }

        it { is_expected.to be true }
      end

      context 'provided source_range on line with comment' do
        let(:range) { hash.pairs.last.source_range }

        it { is_expected.to be true }
      end

      context 'provided a multiline source_range with at least one line with comment' do
        let(:range) { array.source_range }

        it { is_expected.to be true }
      end
    end

    describe '#comments_before_line' do
      let(:source) { <<~RUBY }
        # comment one
        # comment two
        [ 1, 2 ]
        # comment three
      RUBY

      it 'returns comments on or before given line' do
        expect(processed_source.comments_before_line(1).size).to eq 1
        expect(processed_source.comments_before_line(2).size).to eq 2
        expect(processed_source.comments_before_line(3).size).to eq 2
        expect(processed_source.comments_before_line(4).size).to eq 3

        expect(processed_source.comments_before_line(1)
                               .first).to be_a(Parser::Source::Comment)
      end
    end
  end

  context 'token enumerables' do
    let(:source) { <<~RUBY }
      foo(1, 2)
    RUBY

    describe '#each_token' do
      it 'yields all tokens' do
        tokens = []

        processed_source.each_token do |item|
          expect(item).to be_a(RuboCop::AST::Token)
          tokens << item
        end

        expect(tokens.size).to eq 7
      end
    end

    describe '#find_token' do
      it 'yields correct token' do
        token = processed_source.find_token(&:comma?)

        expect(token.text).to eq ','
      end

      it 'yields nil when there is no match' do
        token = processed_source.find_token(&:right_bracket?)

        expect(token).to be_nil
      end
    end
  end

  describe '#file_path' do
    it 'returns file path' do
      expect(processed_source.file_path).to eq path
    end
  end

  describe '#blank?' do
    context 'with source of no content' do
      let(:source) { '' }

      it 'returns true' do
        expect(processed_source).to be_blank
      end
    end

    context 'with source with content' do
      let(:source) { <<~RUBY }
        foo
      RUBY

      it 'returns false' do
        expect(processed_source).not_to be_blank
      end
    end
  end

  # rubocop:disable RSpec/RedundantPredicateMatcher
  describe '#start_with?' do
    context 'with blank source' do
      let(:source) { '' }

      it 'returns false' do
        expect(processed_source).not_to be_start_with('start')
        expect(processed_source).not_to be_start_with('#')
        expect(processed_source).not_to be_start_with('')
      end
    end

    context 'with present source' do
      let(:source) { <<~RUBY }
        foo
      RUBY

      it 'returns true when passed string that starts source' do
        expect(processed_source).to be_start_with('foo')
        expect(processed_source).to be_start_with('f')
        expect(processed_source).to be_start_with('')
      end

      it 'returns false when passed string that does not start source' do
        expect(processed_source).not_to be_start_with('bar')
        expect(processed_source).not_to be_start_with('qux')
        expect(processed_source).not_to be_start_with('1')
      end
    end
  end
  # rubocop:enable RSpec/RedundantPredicateMatcher

  # FIXME: https://github.com/ruby/prism/issues/2467
  describe '#preceding_line', broken_on: :prism do
    let(:source) { <<~RUBY }
      [ line, 1 ]
      { line: 2 }
      # line 3
    RUBY

    it 'returns source of line before token' do
      brace_token = processed_source.find_token(&:left_brace?)
      expect(processed_source.preceding_line(brace_token)).to eq '[ line, 1 ]'

      comment_token = processed_source.find_token(&:comment?)
      expect(processed_source.preceding_line(comment_token)).to eq '{ line: 2 }'
    end
  end

  # FIXME: https://github.com/ruby/prism/issues/2467
  describe '#following_line', broken_on: :prism do
    let(:source) { <<~RUBY }
      [ line, 1 ]
      { line: 2 }
      # line 3
    RUBY

    it 'returns source of line after token' do
      bracket_token = processed_source.find_token(&:right_bracket?)
      expect(processed_source.following_line(bracket_token)).to eq '{ line: 2 }'

      brace_token = processed_source.find_token(&:left_brace?)
      expect(processed_source.following_line(brace_token)).to eq '# line 3'
    end
  end

  describe '#tokens_within' do
    let(:source) { <<~RUBY }
      foo(1, 2)
      bar(3)
    RUBY

    it 'returns tokens for node' do
      node = ast.children[1]
      tokens = processed_source.tokens_within(node.source_range)

      expect(tokens.map(&:text)).to eq(['bar', '(', '3', ')'])
    end

    it 'accepts Node as an argument' do
      node = ast.children[1]
      tokens = processed_source.tokens_within(node)

      expect(tokens.map(&:text)).to eq(['bar', '(', '3', ')'])
    end

    context 'when heredoc as argument is present' do
      let(:source) { <<~RUBY }
        foo(1, [before], <<~DOC, [after])
          inside heredoc.
        DOC
        bar(2)
      RUBY

      it 'returns tokens for node before heredoc' do
        node = ast.children[0].arguments[1]
        tokens = processed_source.tokens_within(node.source_range)

        expect(tokens.map(&:text)).to eq(['[', 'before', ']'])
      end

      it 'returns tokens for heredoc node' do
        node = ast.children[0].arguments[2]
        tokens = processed_source.tokens_within(node.source_range)

        expect(tokens.map(&:text)).to eq(['<<"'])
      end

      it 'returns tokens for node after heredoc' do
        node = ast.children[0].arguments[3]
        tokens = processed_source.tokens_within(node.source_range)

        expect(tokens.map(&:text)).to eq(['[', 'after', ']'])
      end
    end
  end

  describe '#first_token_of' do
    let(:source) { <<~RUBY }
      foo(1, 2)
      bar(3)
    RUBY

    it 'returns first token for node' do
      node = ast.children[1]
      expect(processed_source.first_token_of(node.source_range).text).to eq('bar')
    end

    it 'accepts Node as an argument' do
      node = ast.children[1]
      expect(processed_source.first_token_of(node).text).to eq('bar')
    end
  end

  describe '#last_token_of' do
    let(:source) { <<~RUBY }
      foo(1, 2)
      bar = baz
    RUBY

    it 'returns last token for node' do
      node = ast.children[1]
      expect(processed_source.last_token_of(node.source_range).text).to eq('baz')
    end

    it 'accepts Node as an argument' do
      node = ast.children[1]
      expect(processed_source.last_token_of(node).text).to eq('baz')
    end
  end
end
