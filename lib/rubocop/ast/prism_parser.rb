# frozen_string_literal: true

module RuboCop
  module AST
    # A syntax error or a warning that `parser` has no message for, reported
    # with the message of Prism.
    class PrismDiagnostic < ::Parser::Diagnostic
      attr_reader :message

      def initialize(message, level, reason, location)
        @message = message
        super(level, reason, {}, location, [])
      end
    end

    # Parses a source with Prism and builds the AST, the comments, the tokens
    # and the diagnostics from the result, without `Prism::Translation::Parser`
    # and without the parser classes of the `parser` gem. What it returns is
    # meant to be the same as what the translation layer returns.
    #
    # @api private
    class PrismParser # rubocop:disable Metrics/ClassLength
      Diagnostic = ::Parser::Diagnostic
      PRISM_VERSIONS = { 3.3 => '3.3.1', 3.4 => '3.4.0', 3.5 => '4.0.0', 4.0 => '4.0.0',
                         4.1 => '4.1.0' }.freeze
      # The tokens of Prism 1 need lexer states to be converted, which is
      # something that only the translation layer knows how to do.
      NATIVE_TOKENS = !::Prism::VERSION.start_with?('1.')
      private_constant :Diagnostic, :PRISM_VERSIONS, :NATIVE_TOKENS

      attr_reader :diagnostics

      # @param ruby_version [Float] the Ruby version to parse the source as
      # @param prism [#parse_lex] what provides the result of Prism
      def initialize(ruby_version, prism: ::Prism)
        @prism_version = PRISM_VERSIONS.find { |version, _| version == ruby_version }&.last
        unless @prism_version
          raise ArgumentError, 'RuboCop supports target Ruby versions 3.3 and above with Prism. ' \
                               "Specified target Ruby version: #{ruby_version.inspect}"
        end
        @prism = prism
        @diagnostics = Diagnostic::Engine.new
      end

      # @return [Array] the AST, the comments and a callable that returns the
      #   tokens in the format of the `parser` gem
      def tokenize_deferred(source_buffer)
        @source_buffer = source_buffer
        source = source_buffer.source
        @offset_cache = build_offset_cache(source)

        result = @prism.parse_lex(source, **prism_options)
        process_diagnostics(result)
        program, tokens = result.value
        ast = build_ast(program) if result.success?

        [ast, build_comments(result.comments), deferred_tokens(tokens)]
      end

      private

      def prism_options
        options = { filepath: @source_buffer.name, version: @prism_version, partial_script: true }
        options[:encoding] = false if @source_buffer.source.encoding != Encoding::BINARY
        options
      end

      # Prism counts in bytes, `parser` in characters.
      def build_offset_cache(source)
        return ->(offset) { offset } if source.bytesize == source.length

        offset_cache = []
        offset = 0
        source.each_char do |char|
          char.bytesize.times { offset_cache << offset }
          offset += 1
        end
        offset_cache << offset
      end

      def range(location)
        ::Parser::Source::Range.new(
          @source_buffer, @offset_cache[location.start_offset], @offset_cache[location.end_offset]
        )
      end

      def build_ast(program)
        program.accept(PrismCompiler.new(@source_buffer, @offset_cache, diagnostics))
      end

      def build_comments(comments)
        comments.map { |comment| ::Parser::Source::Comment.new(range(comment.location)) }
      end

      def deferred_tokens(tokens)
        lexer = NATIVE_TOKENS ? PrismLexer : ::Prism::Translation::Parser.const_get(:Lexer)

        -> { lexer.new(@source_buffer, tokens, @offset_cache).to_a }
      end

      def process_diagnostics(result)
        result.errors.each { |error| diagnostics.process(error_diagnostic(error)) }
        result.warnings.each do |warning|
          diagnostic = warning_diagnostic(warning)
          diagnostics.process(diagnostic) if diagnostic
        end
      end

      # rubocop:disable Metrics, Naming/VariableNumber -- one branch for each kind of error of Prism
      def error_diagnostic(error)
        location = error.location
        diagnostic_location = range(location)

        case error.type
        when :argument_block_multi
          Diagnostic.new(:error, :block_and_blockarg, {}, diagnostic_location, [])
        when :argument_formal_constant
          Diagnostic.new(:error, :argument_const, {}, diagnostic_location, [])
        when :argument_formal_class
          Diagnostic.new(:error, :argument_cvar, {}, diagnostic_location, [])
        when :argument_formal_global
          Diagnostic.new(:error, :argument_gvar, {}, diagnostic_location, [])
        when :argument_formal_ivar
          Diagnostic.new(:error, :argument_ivar, {}, diagnostic_location, [])
        when :argument_no_forwarding_amp
          Diagnostic.new(:error, :no_anonymous_blockarg, {}, diagnostic_location, [])
        when :argument_no_forwarding_star
          Diagnostic.new(:error, :no_anonymous_restarg, {}, diagnostic_location, [])
        when :argument_no_forwarding_star_star
          Diagnostic.new(:error, :no_anonymous_kwrestarg, {}, diagnostic_location, [])
        when :begin_lonely_else
          location = location.copy(length: 4)
          diagnostic_location = range(location)
          Diagnostic.new(:error, :useless_else, {}, diagnostic_location, [])
        when :class_name, :module_name
          Diagnostic.new(:error, :module_name_const, {}, diagnostic_location, [])
        when :class_in_method
          Diagnostic.new(:error, :class_in_def, {}, diagnostic_location, [])
        when :def_endless_setter
          Diagnostic.new(:error, :endless_setter, {}, diagnostic_location, [])
        when :embdoc_term
          Diagnostic.new(:error, :embedded_document, {}, diagnostic_location, [])
        when :incomplete_variable_class, :incomplete_variable_class_3_3
          location = location.copy(length: location.length + 1)
          diagnostic_location = range(location)

          Diagnostic.new(:error, :cvar_name, { name: location.slice }, diagnostic_location, [])
        when :incomplete_variable_instance, :incomplete_variable_instance_3_3
          location = location.copy(length: location.length + 1)
          diagnostic_location = range(location)

          Diagnostic.new(:error, :ivar_name, { name: location.slice }, diagnostic_location, [])
        when :invalid_variable_global, :invalid_variable_global_3_3
          Diagnostic.new(:error, :gvar_name, { name: location.slice }, diagnostic_location, [])
        when :module_in_method
          Diagnostic.new(:error, :module_in_def, {}, diagnostic_location, [])
        when :numbered_parameter_ordinary
          Diagnostic.new(:error, :ordinary_param_defined, {}, diagnostic_location, [])
        when :numbered_parameter_outer_scope
          Diagnostic.new(:error, :numparam_used_in_outer_scope, {}, diagnostic_location, [])
        when :parameter_circular
          Diagnostic.new(:error, :circular_argument_reference, { var_name: location.slice }, diagnostic_location, [])
        when :parameter_name_repeat
          Diagnostic.new(:error, :duplicate_argument, {}, diagnostic_location, [])
        when :parameter_numbered_reserved
          Diagnostic.new(:error, :reserved_for_numparam, { name: location.slice }, diagnostic_location, [])
        when :regexp_unknown_options
          Diagnostic.new(:error, :regexp_options, { options: location.slice[1..] }, diagnostic_location, [])
        when :singleton_for_literals
          Diagnostic.new(:error, :singleton_literal, {}, diagnostic_location, [])
        when :string_literal_eof
          Diagnostic.new(:error, :string_eof, {}, diagnostic_location, [])
        when :unexpected_token_ignore
          Diagnostic.new(:error, :unexpected_token, { token: location.slice }, diagnostic_location, [])
        when :write_target_in_method
          Diagnostic.new(:error, :dynamic_const, {}, diagnostic_location, [])
        else
          PrismDiagnostic.new(error.message, :error, error.type, diagnostic_location)
        end
      end

      def warning_diagnostic(warning)
        diagnostic_location = range(warning.location)

        case warning.type
        when :ambiguous_first_argument_plus
          Diagnostic.new(:warning, :ambiguous_prefix, { prefix: '+' }, diagnostic_location, [])
        when :ambiguous_first_argument_minus
          Diagnostic.new(:warning, :ambiguous_prefix, { prefix: '-' }, diagnostic_location, [])
        when :ambiguous_prefix_ampersand
          Diagnostic.new(:warning, :ambiguous_prefix, { prefix: '&' }, diagnostic_location, [])
        when :ambiguous_prefix_star
          Diagnostic.new(:warning, :ambiguous_prefix, { prefix: '*' }, diagnostic_location, [])
        when :ambiguous_prefix_star_star
          Diagnostic.new(:warning, :ambiguous_prefix, { prefix: '**' }, diagnostic_location, [])
        when :ambiguous_slash
          Diagnostic.new(:warning, :ambiguous_regexp, {}, diagnostic_location, [])
        when :dot_dot_dot_eol
          Diagnostic.new(:warning, :triple_dot_at_eol, {}, diagnostic_location, [])
        when :duplicated_hash_key
          # PrismCompiler reports it, in the way `parser` does.
        else
          PrismDiagnostic.new(warning.message, :warning, warning.type, diagnostic_location)
        end
      end
      # rubocop:enable Metrics, Naming/VariableNumber
    end
  end
end
