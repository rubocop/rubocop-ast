# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'rubocop/ast/version'

Gem::Specification.new do |s|
  s.name = 'rubocop-ast'
  s.version = RuboCop::AST::Version::STRING
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.5.0'
  s.authors = ['Bozhidar Batsov', 'Jonas Arvidsson', 'Yuji Nakayama']
  s.description = <<-DESCRIPTION
    RuboCop's Node and NodePattern classes.
  DESCRIPTION

  s.email = 'rubocop@googlegroups.com'
  s.files = `git ls-files lib LICENSE.txt README.md`
            .split($RS) + %w[
              lib/rubocop/ast/node_pattern/parser.racc.rb
              lib/rubocop/ast/node_pattern/lexer.rex.rb
            ]
  s.extra_rdoc_files = ['LICENSE.txt', 'README.md']
  s.homepage = 'https://github.com/rubocop/rubocop-ast'
  s.licenses = ['MIT']
  s.summary = 'RuboCop tools to deal with Ruby code AST.'

  s.metadata = {
    'homepage_uri' => 'https://www.rubocop.org/',
    'changelog_uri' => 'https://github.com/rubocop/rubocop-ast/blob/master/CHANGELOG.md',
    'source_code_uri' => 'https://github.com/rubocop/rubocop-ast/',
    'documentation_uri' => 'https://docs.rubocop.org/rubocop-ast/',
    'bug_tracker_uri' => 'https://github.com/rubocop/rubocop-ast/issues'
  }

  s.add_runtime_dependency('parser', '>= 3.0.1.1')

  s.add_development_dependency('bundler', '>= 1.15.0', '< 3.0')

  ##### Do NOT add `rubocop` (or anything depending on `rubocop`) here. See Gemfile
end
