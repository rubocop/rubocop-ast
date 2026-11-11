# frozen_string_literal: true

require 'ast'

# The part of the `parser` gem that every parser engine needs: the node base
# class, the source layer (buffers, ranges, comments, source maps, the tree
# rewriter) and the diagnostics. The parsers, the lexer and the builders are
# only needed by the `parser_whitequark` and `parser_prism` engines, so they
# are loaded the first time something refers to them.
module Parser
  %w[
    version messages deprecation ast/node meta
    source/buffer source/range source/comment source/comment/associator
    source/tree_rewriter source/tree_rewriter/action
    source/map source/map/operator source/map/collection source/map/constant
    source/map/variable source/map/keyword source/map/definition
    source/map/method_definition source/map/send source/map/index
    source/map/condition source/map/ternary source/map/for
    source/map/rescue_body source/map/heredoc source/map/objc_kwarg
    syntax_error clobbering_error unknown_encoding_in_magic_comment_error
    diagnostic diagnostic/engine
  ].each { |file| require "parser/#{file}" }

  # Loads the rest of `parser` when something refers to a constant that was
  # left out above, like `Parser::Base` or `Parser::Builders::Default`.
  # @api private
  module LazyConstants
    def const_missing(name)
      return super unless require('parser') && const_defined?(name, false)

      const_get(name, false)
    end
  end

  [self, AST, Source].each { |mod| mod.extend(LazyConstants) }
end
