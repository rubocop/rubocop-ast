# frozen_string_literal: true

# Finds the first difference between the tokens, the comments and the
# diagnostics of two processed sources.
class ResultsDiff
  KINDS = %i[tokens comments diagnostics].freeze

  # @return [String, nil] a description of the first difference, if there is one
  def call(expected, actual)
    KINDS.each do |kind|
      difference = difference(kind, send(kind, expected), send(kind, actual))
      return difference if difference
    end
    nil
  end

  private

  def difference(kind, expected, actual)
    return if expected == actual

    index = (0..expected.size).find { |i| expected[i] != actual[i] }
    "#{kind}[#{index}] (difference): #{expected[index].inspect} != #{actual[index].inspect}"
  end

  def tokens(processed_source)
    processed_source.tokens.map do |token|
      [token.type, token.text, token.text.encoding, token.begin_pos, token.end_pos]
    end
  end

  def comments(processed_source)
    processed_source.comments.map { |comment| [comment.text, comment.loc.expression.to_a] }
  end

  def diagnostics(processed_source)
    processed_source.diagnostics.map do |diagnostic|
      [diagnostic.level, diagnostic.reason, diagnostic.message, diagnostic.location.to_a]
    end
  end
end
