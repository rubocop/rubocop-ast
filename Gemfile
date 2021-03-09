# frozen_string_literal: true

##### IMPORTANT: All dependencies that require 'rubocop'
##### MUST be in the `else` section below!
##### This is so we can run our specs completely independently from RuboCop

source 'https://rubygems.org'

gemspec

gem 'bump', require: false
gem 'oedipus_lex', require: false
gem 'racc'
gem 'rake', '~> 13.0'
gem 'rspec', '~> 3.7'
# Workaround for cc-test-reporter with SimpleCov 0.18.
# Stop upgrading SimpleCov until the following issue will be resolved.
# https://github.com/codeclimate/test-reporter/issues/418
gem 'simplecov', '~> 0.10', '< 0.18'

if ENV['RUBOCOP_VERSION'] == 'none'
  # Set this way on CI
  puts 'Running specs independently of RuboCop'
else
  local_ast = File.expand_path('../rubocop', __dir__)
  if File.exist?(local_ast)
    gem 'rubocop', path: local_ast
  elsif ENV['RUBOCOP_VERSION'] == 'master'
    gem 'rubocop', git: 'https://github.com/rubocop-hq/rubocop.git'
  else
    gem 'rubocop', '>= 1.0'
  end
  gem 'rubocop-performance'
  gem 'rubocop-rspec'
end

local_gemfile = File.expand_path('Gemfile.local', __dir__)
eval_gemfile local_gemfile if File.exist?(local_gemfile)
