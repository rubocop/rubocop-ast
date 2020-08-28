# frozen_string_literal: true

require_relative 'lexer.rex'

module RuboCop
  module AST
    class NodePattern
      # Lexer class for `NodePattern`
      class Lexer < LexerRex
        Error = ScanError

        attr_reader :source_buffer, :comments, :tokens

        def initialize(source)
          @tokens = []
          super()
          parse(source)
        end

        private

        # @return [token]
        def emit(type)
          value = ss.captures.first || ss.matched
          value = yield value if block_given?
          token = token(type, value)
          @tokens << token
          token
        end

        def emit_comment
          nil
        end

        def do_parse
          # Called by the generated `parse` method, do nothing here.
        end

        def token(type, value)
          [type, value]
        end

        class WithLoc < Lexer
          attr_reader :source_buffer

          def initialize(str_or_buffer)
            @source_buffer = if str_or_buffer.respond_to?(:source)
                               str_or_buffer
                             else
                               ::Parser::Source::Buffer.new('(string)', source: str_or_buffer)
                             end
            @comments = []
            super(@source_buffer.source)
          end

          def token(type, value)
            super(type, [value, pos])
          end

          def emit_comment
            @comments << Comment.new(pos)
            super
          end

          # @return [::Parser::Source::Range] last match's position
          def pos
            ::Parser::Source::Range.new(source_buffer, ss.pos - ss.matched_size, ss.pos)
          end
        end
      end
    end
  end
end
