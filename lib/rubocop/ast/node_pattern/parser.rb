# frozen_string_literal: true

require 'strscan'

module RuboCop
  module AST
    class NodePattern
      # Lexer class for `NodePattern`
      #
      # Doc on how this fits in the compiling process:
      #   /docs/modules/ROOT/pages/node_pattern.adoc
      class Lexer # rubocop:disable Metrics/ClassLength
        CONST_NAME  = /[A-Z:][a-zA-Z_:]+/.freeze
        SYMBOL_NAME = %r{[\w+@*/?!<>=~|%^&-]+|\[\]=?}.freeze
        IDENTIFIER  = /[a-z][a-zA-Z0-9_]*/.freeze
        NODE_TYPE   = /[a-z][a-zA-Z0-9_-]*/.freeze
        CALL        = /(?:#{CONST_NAME}\.)?#{IDENTIFIER}[!?]?/.freeze
        REGEXP_BODY = %r{(?:[^/]|\\/)*}.freeze
        REGEXP      = %r{/(#{REGEXP_BODY})(?<!\\)/([imxo]*)}.freeze

        class LexerError < StandardError
        end

        class ScanError < LexerError
        end

        Error = ScanError

        REGEXP_OPTIONS = {
          'i' => ::Regexp::IGNORECASE,
          'm' => ::Regexp::MULTILINE,
          'x' => ::Regexp::EXTENDED,
          'o' => 0
        }.freeze
        private_constant :REGEXP_OPTIONS

        # The file name / path
        attr_accessor :filename

        # The StringScanner for this lexer.
        attr_accessor :ss

        # The current lexical state.
        attr_accessor :state

        alias match ss

        attr_reader :source_buffer, :comments, :tokens

        def initialize(source)
          @tokens = []
          super()
          parse(source)
        end

        # private

        ##
        # The match groups for the current scan.
        def matches
          m = (1..9).map { |i| ss[i] }
          m.pop until m[-1] || m.empty?
          m
        end

        ##
        # Yields on the current action.
        def action
          yield
        end

        ##
        # The current scanner class. Must be overridden in subclasses.
        unless instance_methods(false).map(&:to_s).include?('scanner_class')
          def scanner_class
            StringScanner
          end
        end

        ##
        # Parse the given string.
        def parse(str)
          self.ss = scanner_class.new str
          self.state ||= nil
          do_parse
        end

        ##
        # Read in and parse the file at +path+.
        def parse_file(path)
          self.filename = path
          open(path) { |f| parse(f.read) } # rubocop:disable Security/Open
        end

        ##
        # The current location in the parse.
        def location
          filename || '<input>'
        end

        # @return [token]
        def emit(type)
          value = ss[1] || ss.matched
          value = yield value if block_given?
          token = token(type, value)
          @tokens << token
          token
        end

        def emit_comment
          nil
        end

        def emit_regexp
          body = ss[1]
          options = ss[2]
          flag = options.each_char.sum { |c| REGEXP_OPTIONS[c] }

          emit(:tREGEXP) { Regexp.new(body, flag) }
        end

        def do_parse
          # Called by the generated `parse` method, do nothing here.
        end

        def token(type, value)
          [type, value]
        end

        ##
        # Lex the next token.
        def next_token # rubocop:disable Metrics
          token = nil

          until ss.eos? || token
            token =
              case state
              when nil
                case # rubocop:disable Style/EmptyCaseCondition
                when ss.skip(/\s+/)
                  # do nothing
                when ss.skip(/:(#{SYMBOL_NAME})/o)
                  action { emit :tSYMBOL, &:to_sym }
                when ss.skip(/"(.+?)"/)
                  action { emit :tSTRING }
                when ss.skip(/[-+]?\d+\.\d+/)
                  action { emit :tNUMBER, &:to_f }
                when ss.skip(/[-+]?\d+/)
                  action { emit :tNUMBER, &:to_i }
                when ss.skip(/#{Regexp.union(%w"( ) { | } [ ] < > $ ! ^ ` ... + * ? ,")}/o)
                  action { emit ss.matched, &:to_sym }
                when ss.skip(/#{REGEXP}/o)
                  action { emit_regexp }
                when ss.skip(/%?(#{CONST_NAME})/o)
                  action { emit :tPARAM_CONST }
                when ss.skip(/%([a-z_]+)/)
                  action { emit :tPARAM_NAMED }
                when ss.skip(/%(\d*)/)
                  # rubocop:disable Metrics/BlockNesting
                  action { emit(:tPARAM_NUMBER) { |s| s.empty? ? 1 : s.to_i } } # Map `%` to `%1`
                  # rubocop:enable Metrics/BlockNesting
                when ss.skip(/_(#{IDENTIFIER})/o)
                  action { emit :tUNIFY }
                when ss.skip(/_/o)
                  action { emit :tWILDCARD }
                when ss.skip(/\#(#{CALL})/o)
                  action do
                    @state = :ARG
                    emit :tFUNCTION_CALL, &:to_sym
                  end
                when ss.skip(/#{IDENTIFIER}\?/o)
                  action do
                    @state = :ARG
                    emit :tPREDICATE, &:to_sym
                  end
                when ss.skip(/#{NODE_TYPE}/o)
                  action { emit :tNODE_TYPE, &:to_sym }
                when ss.skip(/\#.*/)
                  action { emit_comment }
                else
                  text = ss.string[ss.pos..]
                  raise ScanError, "can not match (#{state.inspect}) at #{location}: '#{text}'"
                end
              when :ARG
                case # rubocop:disable Style/EmptyCaseCondition
                when ss.skip(/\(/)
                  action do
                    @state = nil
                    emit :tARG_LIST
                  end
                when ss.skip(//)
                  action { @state = nil }
                else
                  text = ss.string[ss.pos..]
                  raise ScanError, "can not match (#{state.inspect}) at #{location}: '#{text}'"
                end
              else
                raise ScanError, "undefined state at #{location}: '#{state}'"
              end
            next unless token
          end

          raise LexerError, "bad lexical result at #{location}: #{token.inspect}" unless
            token.nil? || (token.is_a?(Array) && token.size >= 2)

          # auto-switch state
          self.state = token.last if token && token.first == :state

          token
        end
      end

      # Effectively a sliding window over the lexer.
      class Tokens
        def initialize(lexer)
          @lexer = lexer
          @tokens = []
          @index = 0
        end

        def last
          @tokens.last || [nil, nil]
        end

        def try
          index = @index

          if (result = yield)
            result
          else
            @index = index
            false
          end
        end

        def peek
          if @index < @tokens.size
            @tokens[@index]
          elsif (token = @lexer.next_token)
            @tokens << token
            token
          else
            [nil, nil]
          end
        end

        def peek_type
          peek[0]
        end

        def next_token
          if @index < @tokens.size
            token = @tokens[@index]
            @index += 1
            token
          elsif (token = @lexer.next_token)
            @tokens << token
            @index += 1
            token
          else
            [nil, nil]
          end
        end

        def next_type
          next_token[0]
        end

        def next_value
          next_token[1]
        end
      end

      # Parser for NodePattern
      #
      # Doc on how this fits in the compiling process:
      #   /docs/modules/ROOT/pages/node_pattern.adoc
      class Parser # rubocop:disable Metrics/ClassLength
        Builder = NodePattern::Builder
        Lexer = NodePattern::Lexer

        def initialize(builder = self.class::Builder.new)
          super()
          @builder = builder
        end

        ##
        # (Similar API to `parser` gem)
        # Parses a source and returns the AST.
        #
        # @param [Parser::Source::Buffer, String] source_buffer The source buffer to parse.
        # @return [NodePattern::Node]
        #
        def parse(source) # rubocop:disable Metrics/MethodLength
          lexer = self.class::Lexer.new(source)
          tokens = Tokens.new(lexer)

          if (result = parse_node_pattern(tokens))
            if (token = lexer.next_token)
              raise NodePattern::Invalid, "parse error, expected end of input but got #{token[0]}"
            end

            result
          else
            token = tokens.last
            type = token[0] || '?'
            raise NodePattern::Invalid, "parse error on value #{type.inspect} (#{token[1]})"
          end
        rescue Lexer::Error => e
          raise NodePattern::Invalid, e.message
        end

        def inspect
          "<##{self.class}>"
        end

        private

        def parse_node_pattern(tokens)
          if (result = parse_node_pattern_no_union(tokens))
            result
          elsif (result = parse_union(tokens))
            if result.arity != 1
              detail = result.loc&.expression&.source || result.to_s
              raise NodePattern::Invalid, 'parse error, expected unary node pattern ' \
                                          "but got expression matching multiple elements: #{detail}"
            end

            result
          end
        end

        def parse_node_pattern_no_union(tokens) # rubocop:disable Metrics
          case tokens.peek_type
          when '('
            tokens.try do
              start_token = tokens.next_token

              if (result = parse_variadic_pattern(tokens))
                result = [result]
                while (pattern = parse_variadic_pattern(tokens))
                  result << pattern
                end

                if (end_token = tokens.next_token)[0] == ')'
                  @builder.emit_list(:sequence, start_token[1], result, end_token[1])
                end
              end
            end
          when '['
            tokens.try do
              start_token = tokens.next_token
              if (result = parse_node_pattern_list(tokens)) &&
                 (end_token = tokens.next_token)[0] == ']'
                @builder.emit_list(:intersection, start_token[1], result, end_token[1])
              end
            end
          when '!', '^', '`'
            tokens.try do
              operator = tokens.next_token

              if (result = parse_node_pattern(tokens))
                types = { '!' => :negation, '^' => :ascend, '`' => :descend }
                @builder.emit_unary_op(types[operator[0]], operator[1], result)
              end
            end
          when '$'
            tokens.try do
              capture = tokens.next_token
              if (result = parse_node_pattern(tokens))
                @builder.emit_capture(capture[1], result)
              end
            end
          when :tFUNCTION_CALL, :tPREDICATE
            token = tokens.next_token
            args = nil

            tokens.try do
              if ((begin_token = tokens.next_token)[0] == :tARG_LIST) &&
                 (pat = parse_node_pattern(tokens))
                patterns = [pat]
                while tokens.try { (tokens.next_type == ',') && (pat = parse_node_pattern(tokens)) }
                  patterns << pat
                end

                if (end_token = tokens.next_token)[0] == ')'
                  args = [begin_token[1], patterns, end_token[1]]
                end
              end
            end

            types = { tFUNCTION_CALL: :function_call, tPREDICATE: :predicate }
            @builder.emit_call(types[token[0]], token[1], args)
          when :tNODE_TYPE
            @builder.emit_call(:node_type, tokens.next_value)
          when :tSYMBOL
            @builder.emit_atom(:symbol, tokens.next_value)
          when :tNUMBER
            @builder.emit_atom(:number, tokens.next_value)
          when :tSTRING
            @builder.emit_atom(:string, tokens.next_value)
          when :tPARAM_CONST
            @builder.emit_atom(:const, tokens.next_value)
          when :tPARAM_NAMED
            @builder.emit_atom(:named_parameter, tokens.next_value)
          when :tPARAM_NUMBER
            @builder.emit_atom(:positional_parameter, tokens.next_value)
          when :tREGEXP
            @builder.emit_atom(:regexp, tokens.next_value)
          when :tWILDCARD
            @builder.emit_atom(:wildcard, tokens.next_value)
          when :tUNIFY
            @builder.emit_atom(:unify, tokens.next_value)
          end
        end

        def parse_union(tokens)
          tokens.try do
            if ((start_token = tokens.next_token)[0] == '{') &&
               (result = parse_separated_variadic_patterns(tokens)) &&
               ((end_token = tokens.next_token)[0] == '}')
              @builder.emit_union(start_token[1], result, end_token[1])
            end
          end
        end

        def parse_variadic_pattern(tokens)
          if (result = parse_node_pattern_no_union(tokens) || parse_union(tokens))
            if ['?', '*', '+'].include?(tokens.peek_type)
              repetition = tokens.next_value
              @builder.emit_unary_op(:repetition, repetition, result, repetition)
            else
              result
            end
          else
            parse_capture(tokens) || parse_rest(tokens)
          end
        end

        def parse_capture(tokens) # rubocop:disable Metrics/AbcSize
          tokens.try do
            capture = tokens.next_value if tokens.peek_type == '$'

            if ((open_bracket = tokens.next_token)[0] == '<') &&
               (pattern = parse_node_pattern_list(tokens))
              rest = parse_rest(tokens)

              if (close_bracket = tokens.next_token)[0] == '>'
                pattern << rest if rest

                list = @builder.emit_list(:any_order, open_bracket[1], pattern, close_bracket[1])
                @builder.emit_capture(capture, list)
              end
            end
          end
        end

        def parse_rest(tokens)
          tokens.try do
            capture = tokens.next_value if tokens.peek_type == '$'

            if (token = tokens.next_token)[0] == '...'
              @builder.emit_capture(capture, @builder.emit_atom(:rest, token[1]))
            end
          end
        end

        def parse_node_pattern_list(tokens)
          if (result = parse_node_pattern(tokens))
            result = [result]
            while (pattern = parse_node_pattern(tokens))
              result << pattern
            end
            result
          end
        end

        def parse_separated_variadic_patterns(tokens)
          patterns = [[]]

          loop do
            if (pattern = parse_variadic_pattern(tokens))
              patterns.last << pattern
            elsif tokens.peek_type == '|'
              tokens.next_token
              patterns << []
            else
              break
            end
          end

          patterns
        end
      end
    end
  end
end
