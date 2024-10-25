# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'rubocop/ast/version'

Gem::Specification.new do |s|
  s.name = 'rubocop-ast'
  s.version = RuboCop::AST::Version::STRING
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.7.0'
  s.authors = ['Bozhidar Batsov', 'Jonas Arvidsson', 'Yuji Nakayama']
  s.description = <<-DESCRIPTION
    RuboCop's Node and NodePattern classes.
  DESCRIPTION

  s.email = 'rubocop@googlegroups.com'
  s.files = `git ls-files lib LICENSE.txt README.md`
            .lines(chomp: true) + %w[
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
    'bug_tracker_uri' => 'https://github.com/rubocop/rubocop-ast/issues',
    'rubygems_mfa_required' => 'true'
  }

  s.add_dependency('parser', '>= 3.3.1.0')

  ##### Do NOT add `rubocop` (or anything depending on `rubocop`) here. See Gemfile
end
