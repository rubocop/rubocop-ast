# frozen_string_literal: true

module RuboCop
  module AST
    module Ext
      # Extensions to Parser::AST::Range
      module Range
        # @return [Range] the range of line numbers for the node
        # If `exclude_end` is `true`, then the range will be exclusive.
        #
        # Assume that `node` corresponds to the following array literal:
        #
        #   [
        #     :foo,
        #     :bar
        #   ]
        #
        #   node.loc.begin.line_span                       # => 1..1
        #   node.source_range.line_span(exclude_end: true) # => 1...4
        def line_span(exclude_end: false)
          ::Range.new(first_line, last_line, exclude_end)
        end

        # @param [Parser::Source::Range, RuboCop::AST::Node, RuboCop::AST::Token,
        #   Parser::Source::Comment] other
        # @return [Boolean] whether this range starts on the same line as `other`
        def same_line?(other)
          other_line = if other.respond_to?(:line)
                         other.line
                       elsif other.respond_to?(:loc)
                         other.loc.line
                       end

          !other_line.nil? && line == other_line
        end

        # Arbitrarily chosen value, should be enough to cover
        # the most nested source code in real world projects.
        MAX_LINE_BEGINS_REGEX_INDEX = 50
        LINE_BEGINS_REGEX_CACHE = Hash.new do |hash, index|
          hash[index] = /^\s{#{index}}\S/ if index <= MAX_LINE_BEGINS_REGEX_INDEX
        end
        private_constant :MAX_LINE_BEGINS_REGEX_INDEX, :LINE_BEGINS_REGEX_CACHE

        # @return [Boolean] whether this range begins its line, i.e. is preceded
        #   only by whitespace
        def begins_its_line?
          if (regex = LINE_BEGINS_REGEX_CACHE[column])
            source_line.match?(regex)
          else
            source_line.index(/\S/) == column
          end
        end
      end
    end
  end
end

Parser::Source::Range.include RuboCop::AST::Ext::Range
