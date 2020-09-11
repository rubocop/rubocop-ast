# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'bump', require: false
gem 'pry'
gem 'rake', '~> 12.0'
gem 'rspec', '~> 3.7'
local_ast = File.expand_path('../rubocop', __dir__)
if Dir.exist? local_ast
  gem 'rubocop', path: local_ast
else
  gem 'rubocop', '~> 0.89'
end
gem 'rubocop-performance', '~> 1.0'
gem 'rubocop-rspec', '~> 1.0'
# Workaround for cc-test-reporter with SimpleCov 0.18.
# Stop upgrading SimpleCov until the following issue will be resolved.
# https://github.com/codeclimate/test-reporter/issues/418
gem 'simplecov', '~> 0.10', '< 0.18'

local_gemfile = File.expand_path('Gemfile.local', __dir__)
eval_gemfile local_gemfile if File.exist?(local_gemfile)

# #### Do NOT add `rubocop` (or anything depending on `rubocop`)
# to insure that this gem remains independent of `rubocop`.
# Bundler loads all dependencies automatically, so specs wouldn't detect it if
# we required a file from `rubocop` gem by mistake.
# Note that `rake internal_investigation` will use `../rubocop` if present.
