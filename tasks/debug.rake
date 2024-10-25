# frozen_string_literal: true

def pattern_or_file(input)
  if input && File.exist?(input)
    File.read(input)
  else
    input
  end
end

desc 'Compile pattern to Ruby code for debugging purposes'
task compile: :generate do
  if (pattern = pattern_or_file(ARGV[1]))
    require_relative '../lib/rubocop/ast'
    puts RuboCop::AST::NodePattern.new(pattern).compile_as_lambda
  else
    puts <<~USAGE
      Usage:
        rake compile '(send nil? :example...)'
        rake compile pattern.txt
    USAGE
  end
  exit(0)
end

desc 'Parse pattern to AST for debugging purposes'
task parse: :generate do
  if (pattern = pattern_or_file(ARGV[1]))
    require_relative '../lib/rubocop/ast'
    puts RuboCop::AST::NodePattern::Parser.new.parse(pattern)
  else
    puts <<~USAGE
      Usage:
        rake parse '(send nil? :example...)'
        rake parse pattern.txt
    USAGE
  end
  exit(0)
end

desc 'Tokens of pattern for debugging purposes'
task tokenize: :generate do
  if (pattern = pattern_or_file(ARGV[1]))
    require_relative '../lib/rubocop/ast'
    parser = RuboCop::AST::NodePattern::Parser::WithMeta.new
    parser.parse(pattern)
    puts parser.tokens
  else
    puts <<~USAGE
      Usage:
        rake tokenize '(send nil? :example...)'
        rake tokenize pattern.txt
    USAGE
  end
  exit(0)
end

desc 'Test pattern against ruby code'
task test_pattern: :generate do
  if (pattern = pattern_or_file(ARGV[1])) && (ruby = pattern_or_file(ARGV[2]))
    require_relative '../lib/rubocop/ast'
    colorizer = RuboCop::AST::NodePattern::Compiler::Debug::Colorizer.new(pattern)
    puts colorizer.test(ruby).colorize
  else
    puts <<~USAGE
      Usage:
        rake test_pattern '(send nil? :example...)' 'example(42)'
        rake test_pattern pattern.txt code.rb
    USAGE
  end
  exit(0)
end
