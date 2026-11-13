# frozen_string_literal: true

require 'ast'

module RuboCop
  module AST
    # Loads the part of the `parser` gem that every parser engine needs: the
    # node base class, the source layer (buffers, ranges, comments, source
    # maps, the tree rewriter) and the diagnostics.
    #
    # They come from the gem when it is installed, because its parsers and
    # builders create objects of the very same classes. Without the gem, a
    # copy of those files that ships with this gem is loaded instead, which is
    # all that the `prism` parser engine needs.
    # @api private
    module ParserSource
      FILES = %w[
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
      ].freeze

      VENDOR_DIR = File.join(__dir__, 'vendor', 'parser')

      VENDORED = begin
        require 'parser/version'
        false
      rescue LoadError
        true
      end
      private_constant :VENDORED

      # Whether the classes come from the copy that ships with this gem,
      # which is the case when the `parser` gem is not installed.
      def self.vendored?
        VENDORED
      end

      def self.ensure_parser_gem(parser_engine)
        return unless vendored?

        raise LoadError, "The `#{parser_engine}` parser engine needs the `parser` gem. Add it " \
                         'to your Gemfile, or use the `prism` parser engine, which supports ' \
                         'target Ruby versions 3.3 and above.'
      end

      begin
        FILES.each { |file| require vendored? ? File.join(VENDOR_DIR, file) : "parser/#{file}" }
      rescue LoadError
        # A version of `parser` that lays out its files in another way.
        require 'parser'
      end

      # Loads the rest of `parser` when something refers to a constant that
      # is not part of the files above, like `Parser::Base` or
      # `Parser::Builders::Default`.
      module LazyConstants
        def const_missing(name)
          return super unless require('parser') && const_defined?(name, false)

          const_get(name, false)
        end
      end

      lazy = vendored? ? [] : [::Parser, ::Parser::AST, ::Parser::Source]
      lazy.each { |mod| mod.extend(LazyConstants) }
    end
  end
end
