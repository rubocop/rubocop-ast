# frozen_string_literal: true

##### IMPORTANT: All dependencies that require 'rubocop'
##### MUST be in the `else` section below!
##### This is so we can run our specs completely independently from RuboCop

source 'https://rubygems.org'

gemspec

gem 'bump', require: false
gem 'bundler', '>= 1.15.0', '< 3.0'
gem 'oedipus_lex', '>= 2.6.0', require: false
gem 'prism', '>= 1.1.0'
gem 'racc'
gem 'rake', '~> 13.0'
gem 'rspec', '~> 3.7'
gem 'simplecov', '~> 0.20'

if ENV.fetch('RUBOCOP_VERSION', nil) == 'none'
  # Set this way on CI
  puts 'Running specs independently of RuboCop'
else
  local_ast = File.expand_path('../rubocop', __dir__)
  if File.exist?(local_ast)
    gem 'rubocop', path: local_ast
  elsif ENV.fetch('RUBOCOP_VERSION', nil) == 'master'
    gem 'rubocop', git: 'https://github.com/rubocop/rubocop.git'
  else
    gem 'rubocop', '>= 1.0'
  end
  gem 'rubocop-performance'
  gem 'rubocop-rspec', '~> 3.0.0'
end

local_gemfile = File.expand_path('Gemfile.local', __dir__)
eval_gemfile local_gemfile if File.exist?(local_gemfile)
