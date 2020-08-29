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
      end
    end
  end
end
