# frozen_string_literal: true

task build: :generate
task release: 'changelog:check_clean'

require 'bundler'
require 'bundler/gem_tasks'

Dir['tasks/**/*.rake'].each { |t| load t }

begin
  Bundler.setup
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems'
  exit e.status_code
end

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(spec: :generate) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

desc 'Run RSpec code examples with Prism'
task prism_spec: :generate do
  original_parser_engine = ENV.fetch('PARSER_ENGINE', nil)
  original_target_ruby_version = ENV.fetch('TARGET_RUBY_VERSION', nil)

  RSpec::Core::RakeTask.new(prism_spec: :generate) do |spec|
    # Specify the minimum Ruby version 3.3 required for Prism to analyze.
    ENV['PARSER_ENGINE'] = 'parser_prism'
    ENV['TARGET_RUBY_VERSION'] = '3.3'

    spec.pattern = FileList['spec/**/*_spec.rb']
  end

  ENV['PARSER_ENGINE'] = original_parser_engine
  ENV['TARGET_RUBY_VERSION'] = original_target_ruby_version
end

desc 'Run RSpec with code coverage'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['spec'].execute
end

desc 'Run RuboCop over itself'
task internal_investigation: :generate do
  sh 'rubocop'
end

task default: %i[
  spec
  prism_spec
  internal_investigation
]
