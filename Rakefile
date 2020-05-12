# frozen_string_literal: true

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

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

desc 'Run RSpec with code coverage'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['spec'].execute
end

desc 'Run RuboCop over itself'
task :internal_investigation do
  Bundler.with_unbundled_env do
    local = '../rubocop/exe/rubocop'
    exe = if File.exist?(local)
            "bundle exec --gemfile=../rubocop/Gemfile #{local}"
          else
            'rubocop'
          end
    sh exe
  end
end

task default: %i[
  spec
  internal_investigation
]
