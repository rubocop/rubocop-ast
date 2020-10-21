# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'bump', require: false
gem 'oedipus_lex', require: false
gem 'pry'
gem 'racc'
gem 'rake', '~> 13.0'
gem 'rspec', '~> 3.7'
local_ast = File.expand_path('../rubocop', __dir__)
if Dir.exist? local_ast
  gem 'rubocop', path: local_ast
else
  gem 'rubocop'
end
gem 'rubocop-performance'
# Workaround for cc-test-reporter with SimpleCov 0.18.
# Stop upgrading SimpleCov until the following issue will be resolved.
# https://github.com/codeclimate/test-reporter/issues/418
gem 'simplecov', '~> 0.10', '< 0.18'

local_gemfile = File.expand_path('Gemfile.local', __dir__)
eval_gemfile local_gemfile if File.exist?(local_gemfile)
