# frozen_string_literal: true

desc 'Compile pattern to Ruby code for debugging purposes'
task compile: :generate do
  if (pattern = ARGV[1])
    require_relative '../lib/rubocop/ast'
    puts ::RuboCop::AST::NodePattern.new(pattern).compile_as_lambda
  else
    puts 'Usage:'
    puts "  rake compile '(send nil? :example...)'"
  end
  exit(0)
end

desc 'Parse pattern to AST for debugging purposes'
task parse: :generate do
  if (pattern = ARGV[1])
    require_relative '../lib/rubocop/ast'
    puts ::RuboCop::AST::NodePattern::Parser.new.parse(pattern)
  else
    puts 'Usage:'
    puts "  rake parse '(send nil? :example...)'"
  end
  exit(0)
end

desc 'Tokens of pattern for debugging purposes'
task tokenize: :generate do
  if (pattern = ARGV[1])
    require_relative '../lib/rubocop/ast'
    puts ::RuboCop::AST::NodePattern::Parser::WithMeta.new.tokenize(pattern).last
  else
    puts 'Usage:'
    puts "  rake parse '(send nil? :example...)'"
  end
  exit(0)
end

desc 'Test pattern against ruby code'
task test_pattern: :generate do
  if (pattern = ARGV[1]) && (ruby = ARGV[2])
    require_relative '../lib/rubocop/ast'
    colorizer = ::RuboCop::AST::NodePattern::Compiler::Debug::Colorizer.new(pattern)
    puts colorizer.test(ruby).colorize
  else
    puts 'Usage:'
    puts "  rake test-pattern '(send nil? :example...)' 'example(42)'"
  end
  exit(0)
end
