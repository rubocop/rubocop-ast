# frozen_string_literal: true

require_relative 'lexer.rex'

module RuboCop
  module AST
    class NodePattern
      # Lexer class for `NodePattern`
      # Design isn't super pretty,
      class Lexer < LexerRex
        Error = ScanError

        attr_reader :source_buffer, :comments, :tokens

        def initialize(str_or_buffer)
          super()
          @source_buffer = if str_or_buffer.respond_to?(:source)
                             str_or_buffer
                           else
                             ::Parser::Source::Buffer.new('(string)', source: str_or_buffer)
                           end
          @comments = []
          @tokens = []
          parse(@source_buffer.source)
        end

        private

        # @return [::Parser::Source::Range] last match's position
        def pos
          ::Parser::Source::Range.new(source_buffer, ss.pos - ss.matched_size, ss.pos)
        end

        # @return [token]
        def emit(type)
          value = ss.captures.first || ss.matched
          value = yield value if block_given?
          token = [type, [value, pos]]
          @tokens << token
          token
        end

        def emit_comment
          @comments << Comment.new(pos)

          nil
        end

        def do_parse
          # Called by the generated `parse` method, do nothing here.
        end
      end
    end
  end
end
