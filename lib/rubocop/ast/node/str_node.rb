# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `str`, `dstr`, and `xstr` nodes. This will be used
    # in place of a plain node when the builder constructs the AST, making
    # its methods available to all `str` nodes within RuboCop.
    class StrNode < Node
      include BasicLiteralNode

      def heredoc?
        loc.is_a?(Parser::Source::Map::Heredoc)
      end

      def last_line
        if heredoc?
          loc.heredoc_end.line
        else
          super
        end
      end

      def line_count
        last_line - first_line + 1
      end
    end
  end
end
