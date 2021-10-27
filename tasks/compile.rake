# frozen_string_literal: true

require 'oedipus_lex'
Rake.application.rake_require 'oedipus_lex'

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
