# frozen_string_literal: true

require 'yaml'
require 'rubocop-ast'

if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  SimpleCov.start
end

RSpec.shared_context 'ruby 2.3', :ruby23 do
  let(:ruby_version) { 2.3 }
end

RSpec.shared_context 'ruby 2.4', :ruby24 do
  let(:ruby_version) { 2.4 }
end

RSpec.shared_context 'ruby 2.5', :ruby25 do
  let(:ruby_version) { 2.5 }
end

RSpec.shared_context 'ruby 2.6', :ruby26 do
  let(:ruby_version) { 2.6 }
end

RSpec.shared_context 'ruby 2.7', :ruby27 do
  let(:ruby_version) { 2.7 }
end

module DefaultRubyVersion
  extend RSpec::SharedContext

  let(:ruby_version) { 2.4 }
end

module ParseSourceHelper
  def parse_source(source)
    RuboCop::ProcessedSource.new(source, ruby_version, nil)
  end
end

RSpec.configure do |config|
  config.include ParseSourceHelper
  config.include DefaultRubyVersion

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  config.order = :random
  Kernel.srand config.seed
end
