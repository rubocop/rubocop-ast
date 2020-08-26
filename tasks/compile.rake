# frozen_string_literal: true

Rake.application.rake_require 'oedipus_lex'

# Patch gem, see https://github.com/seattlerb/oedipus_lex/pull/15
class OedipusLex
  remove_const :RE
  RE = %r{(/(?:\\.|[^/])*/[ion]?)}.freeze
end

def update_file(path)
  content = File.read(path)
  File.write(path, yield(content))
end

ENCODING_COMMENT = '# frozen_string_literal: true'
GENERATED_FILES = %w[
  lib/rubocop/ast/node_pattern/parser.racc.rb
  lib/rubocop/ast/node_pattern/lexer.rex.rb
].freeze
desc 'Generate the lexer and parser files.'
task generate: %w[generate:lexer generate:parser]

files = {
  lexer: 'lib/rubocop/ast/node_pattern/lexer.rex.rb',
  parser: 'lib/rubocop/ast/node_pattern/parser.racc.rb'
}

CLEAN.include(files.values)
namespace :generate do
  files.each do |kind, filename|
    desc "Generate just the #{kind}"
    task kind => filename do
      update_file(filename) do |content|
        content.prepend ENCODING_COMMENT, "\n" unless content.start_with?(ENCODING_COMMENT)
        content.gsub 'module NodePattern', 'class NodePattern'
      end
    end
  end
end

rule '.racc.rb' => '.y' do |t|
  cmd = "bundle exec racc -l -v -o #{t.name} #{t.source}"
  sh cmd
end

desc 'Compile pattern to Ruby code for debugging purposes'
task :compile do
  require_relative '../lib/rubocop/ast'
  if (pattern = ARGV[1])
    puts ::RuboCop::AST::NodePattern.new(pattern).compile_as_lambda
  else
    puts 'Usage:'
    puts "  rake compile '(send nil? :example...)'"
  end
  exit(0)
end

desc 'Parse pattern to AST for debugging purposes'
task :parse do
  require_relative '../lib/rubocop/ast'
  if (pattern = ARGV[1])
    puts ::RuboCop::AST::NodePattern::Parser.new.parse(pattern)
  else
    puts 'Usage:'
    puts "  rake parse '(send nil? :example...)'"
  end
  exit(0)
end

desc 'Tokens of pattern for debugging purposes'
task :tokenize do
  require_relative '../lib/rubocop/ast'
  if (pattern = ARGV[1])
    puts ::RuboCop::AST::NodePattern::Parser.new.tokenize(pattern).last
  else
    puts 'Usage:'
    puts "  rake parse '(send nil? :example...)'"
  end
  exit(0)
end
