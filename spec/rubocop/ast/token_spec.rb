# frozen_string_literal: true

RSpec.describe RuboCop::AST::Token do
  let(:processed_source) { parse_source(source) }

  let(:source) { <<~RUBY }
    # comment
    def some_method
      [ 1, 2 ];
      foo[0] = 3.to_i
      1..42
      1...42
    end
  RUBY

  let(:first_token) { processed_source.tokens.first }
  let(:comment_token) do
    processed_source.find_token do |t|
      t.text.start_with?('#') && t.line == 1
    end
  end

  let(:left_array_bracket_token) do
    processed_source.find_token { |t| t.text == '[' && t.line == 3 }
  end
  let(:comma_token) { processed_source.find_token { |t| t.text == ',' } }
  let(:irange_token) { processed_source.find_token { |t| t.text == '..' } }
  let(:erange_token) { processed_source.find_token { |t| t.text == '...' } }
  let(:dot_token) { processed_source.find_token { |t| t.text == '.' } }
  let(:right_array_bracket_token) do
    processed_source.find_token { |t| t.text == ']' && t.line == 3 }
  end
  let(:semicolon_token) { processed_source.find_token { |t| t.text == ';' } }

  let(:left_ref_bracket_token) do
    processed_source.find_token { |t| t.text == '[' && t.line == 4 }
  end
  let(:zero_token) { processed_source.find_token { |t| t.text == '0' } }
  let(:right_ref_bracket_token) do
    processed_source.find_token { |t| t.text == ']' && t.line == 4 }
  end
  let(:equals_token) { processed_source.find_token { |t| t.text == '=' } }

  let(:end_token) { processed_source.find_token { |t| t.text == 'end' } }
  let(:new_line_token) { processed_source.find_token { |t| t.line == 7 && t.column == 3 } }

  describe '.from_parser_token' do
    subject(:token) { described_class.from_parser_token(parser_token) }

    let(:parser_token) { [type, [text, range]] }
    let(:type) { :kDEF }
    let(:text) { 'def' }
    let(:range) do
      instance_double(Parser::Source::Range, line: 42, column: 30)
    end

    it "sets parser token's type to rubocop token's type" do
      expect(token.type).to eq(type)
    end

    it "sets parser token's text to rubocop token's text" do
      expect(token.text).to eq(text)
    end

    it "sets parser token's range to rubocop token's pos" do
      expect(token.pos).to eq(range)
    end

    it 'returns a #to_s useful for debugging' do
      expect(token.to_s).to eq('[[42, 30], kDEF, "def"]')
    end
  end

  describe '#line' do
    it 'returns line of token' do
      expect(first_token.line).to eq 1
      expect(zero_token.line).to eq 4
      expect(end_token.line).to eq 7
    end
  end

  describe '#column' do
    it 'returns index of first char in token range on that line' do
      expect(first_token.column).to eq 0
      expect(zero_token.column).to eq 6
      expect(end_token.column).to eq 0
    end
  end

  describe '#begin_pos' do
    it 'returns index of first char in token range of entire source' do
      expect(first_token.begin_pos).to eq 0
      expect(zero_token.begin_pos).to eq 44
      expect(end_token.begin_pos).to eq 73
    end
  end

  describe '#end_pos' do
    it 'returns index of last char in token range of entire source' do
      expect(first_token.end_pos).to eq 9
      expect(zero_token.end_pos).to eq 45
      expect(end_token.end_pos).to eq 76
    end
  end

  describe '#space_after' do
    it 'returns truthy MatchData when there is a space after token' do
      expect(left_array_bracket_token.space_after?).to be_a(MatchData)
      expect(right_ref_bracket_token.space_after?).to be_a(MatchData)

      expect(left_array_bracket_token).to be_space_after
      expect(right_ref_bracket_token).to be_space_after
    end

    it 'returns nil when there is not a space after token' do
      expect(left_ref_bracket_token.space_after?).to be_nil
      expect(zero_token.space_after?).to be_nil
    end
  end

  describe '#to_s' do
    it 'returns string of token data' do
      expect(end_token.to_s).to include end_token.line.to_s
      expect(end_token.to_s).to include end_token.column.to_s
      expect(end_token.to_s).to include end_token.type.to_s
      expect(end_token.to_s).to include end_token.text.to_s
    end
  end

  describe '#space_before' do
    it 'returns truthy MatchData when there is a space before token' do
      expect(left_array_bracket_token.space_before?).to be_a(MatchData)
      expect(equals_token.space_before?).to be_a(MatchData)

      expect(left_array_bracket_token).to be_space_before
      expect(equals_token).to be_space_before
    end

    it 'returns nil when there is not a space before token' do
      expect(semicolon_token.space_before?).to be_nil
      expect(zero_token.space_before?).to be_nil
    end

    it 'returns nil when it is on the first line' do
      expect(processed_source.tokens[0].space_before?).to be_nil
    end
  end

  context 'type predicates' do
    describe '#comment?' do
      it 'returns true for comment tokens' do
        expect(comment_token).to be_comment
      end

      it 'returns false for non comment tokens' do
        expect(zero_token).not_to be_comment
        expect(semicolon_token).not_to be_comment
      end
    end

    describe '#semicolon?' do
      it 'returns true for semicolon tokens' do
        expect(semicolon_token).to be_semicolon
      end

      it 'returns false for non semicolon tokens' do
        expect(comment_token).not_to be_semicolon
        expect(comma_token).not_to be_semicolon
      end
    end

    describe '#left_array_bracket?' do
      it 'returns true for left_array_bracket tokens' do
        expect(left_array_bracket_token).to be_left_array_bracket
      end

      it 'returns false for non left_array_bracket tokens' do
        expect(left_ref_bracket_token).not_to be_left_array_bracket
        expect(right_array_bracket_token).not_to be_left_array_bracket
      end
    end

    describe '#left_ref_bracket?' do
      it 'returns true for left_ref_bracket tokens' do
        expect(left_ref_bracket_token).to be_left_ref_bracket
      end

      it 'returns false for non left_ref_bracket tokens' do
        expect(left_array_bracket_token).not_to be_left_ref_bracket
        expect(right_ref_bracket_token).not_to be_left_ref_bracket
      end
    end

    describe '#left_bracket?' do
      it 'returns true for all left_bracket tokens' do
        expect(left_ref_bracket_token).to be_left_bracket
        expect(left_array_bracket_token).to be_left_bracket
      end

      it 'returns false for non left_bracket tokens' do
        expect(right_ref_bracket_token).not_to be_left_bracket
        expect(right_array_bracket_token).not_to be_left_bracket
      end
    end

    describe '#right_bracket?' do
      it 'returns true for all right_bracket tokens' do
        expect(right_ref_bracket_token).to be_right_bracket
        expect(right_array_bracket_token).to be_right_bracket
      end

      it 'returns false for non right_bracket tokens' do
        expect(left_ref_bracket_token).not_to be_right_bracket
        expect(left_array_bracket_token).not_to be_right_bracket
      end
    end

    describe '#left_brace?' do
      it 'returns true for right_bracket tokens' do
        expect(right_ref_bracket_token).to be_right_bracket
        expect(right_array_bracket_token).to be_right_bracket
      end

      it 'returns false for non right_bracket tokens' do
        expect(left_ref_bracket_token).not_to be_right_bracket
        expect(left_array_bracket_token).not_to be_right_bracket
      end
    end

    describe '#comma?' do
      it 'returns true for comma tokens' do
        expect(comma_token).to be_comma
      end

      it 'returns false for non comma tokens' do
        expect(semicolon_token).not_to be_comma
        expect(right_ref_bracket_token).not_to be_comma
      end
    end

    describe '#dot?' do
      it 'returns true for dot tokens' do
        expect(dot_token).to be_dot
      end

      it 'returns false for non dot tokens' do
        expect(semicolon_token).not_to be_dot
        expect(right_ref_bracket_token).not_to be_dot
      end
    end

    describe '#regexp_dots?' do
      it 'returns true for regexp tokens' do
        expect(irange_token).to be_regexp_dots
        expect(erange_token).to be_regexp_dots
      end

      it 'returns false for non comma tokens' do
        expect(semicolon_token).not_to be_regexp_dots
        expect(right_ref_bracket_token).not_to be_regexp_dots
      end
    end

    describe '#rescue_modifier?' do
      let(:source) { <<~RUBY }
        def foo
          bar rescue qux
        end
      RUBY

      let(:rescue_modifier_token) do
        processed_source.find_token { |t| t.text == 'rescue' }
      end

      it 'returns true for rescue modifier tokens' do
        expect(rescue_modifier_token).to be_rescue_modifier
      end

      it 'returns false for non rescue modifier tokens' do
        expect(first_token).not_to be_rescue_modifier
        expect(end_token).not_to be_rescue_modifier
      end
    end

    describe '#end?' do
      it 'returns true for end tokens' do
        expect(end_token).to be_end
      end

      it 'returns false for non end tokens' do
        expect(semicolon_token).not_to be_end
        expect(comment_token).not_to be_end
      end
    end

    describe '#equals_sign?' do
      it 'returns true for equals sign tokens' do
        expect(equals_token).to be_equal_sign
      end

      it 'returns false for non equals sign tokens' do
        expect(semicolon_token).not_to be_equal_sign
        expect(comma_token).not_to be_equal_sign
      end
    end

    describe '#new_line?' do
      it 'returns true for new line tokens' do
        expect(new_line_token).to be_a_new_line
      end

      it 'returns false for non new line tokens' do
        expect(end_token).not_to be_a_new_line
        expect(semicolon_token).not_to be_a_new_line
      end
    end

    context 'with braces & parens' do
      let(:source) { <<~RUBY }
        { a: 1 }
        foo { |f| bar(f) }
        -> { f }
      RUBY

      let(:left_hash_brace_token) do
        processed_source.find_token { |t| t.text == '{' && t.line == 1 }
      end
      let(:right_hash_brace_token) do
        processed_source.find_token { |t| t.text == '}' && t.line == 1 }
      end

      let(:left_block_brace_token) do
        processed_source.find_token { |t| t.text == '{' && t.line == 2 }
      end
      let(:left_lambda_brace_token) do
        processed_source.find_token { |t| t.text == '{' && t.line == 3 }
      end
      let(:left_parens_token) do
        processed_source.find_token { |t| t.text == '(' }
      end
      let(:right_parens_token) do
        processed_source.find_token { |t| t.text == ')' }
      end
      let(:right_block_brace_token) do
        processed_source.find_token { |t| t.text == '}' && t.line == 2 }
      end

      describe '#left_brace?' do
        # FIXME: `broken_on: :prism` can be removed when
        # https://github.com/ruby/prism/issues/2454 will be released.
        it 'returns true for left hash brace tokens', broken_on: :prism do
          expect(left_hash_brace_token).to be_left_brace
        end

        it 'returns false for non left hash brace tokens' do
          expect(left_block_brace_token).not_to be_left_brace
          expect(right_hash_brace_token).not_to be_left_brace
        end
      end

      describe '#left_curly_brace?' do
        it 'returns true for left block brace tokens' do
          expect(left_block_brace_token).to be_left_curly_brace
          expect(left_lambda_brace_token).to be_left_curly_brace
        end

        # FIXME: `broken_on: :prism` can be removed when
        # https://github.com/ruby/prism/issues/2454 will be released.
        it 'returns false for non left block brace tokens', broken_on: :prism do
          expect(left_hash_brace_token).not_to be_left_curly_brace
          expect(right_block_brace_token).not_to be_left_curly_brace
        end
      end

      describe '#right_curly_brace?' do
        it 'returns true for all right brace tokens' do
          expect(right_hash_brace_token).to be_right_curly_brace
          expect(right_block_brace_token).to be_right_curly_brace
        end

        it 'returns false for non right brace tokens' do
          expect(left_hash_brace_token).not_to be_right_curly_brace
          expect(left_parens_token).not_to be_right_curly_brace
        end
      end

      describe '#left_parens?' do
        it 'returns true for left parens tokens' do
          expect(left_parens_token).to be_left_parens
        end

        it 'returns false for non left parens tokens' do
          expect(left_hash_brace_token).not_to be_left_parens
          expect(right_parens_token).not_to be_left_parens
        end
      end

      describe '#right_parens?' do
        it 'returns true for right parens tokens' do
          expect(right_parens_token).to be_right_parens
        end

        it 'returns false for non right parens tokens' do
          expect(right_hash_brace_token).not_to be_right_parens
          expect(left_parens_token).not_to be_right_parens
        end
      end
    end
  end
end
