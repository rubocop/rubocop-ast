# frozen_string_literal: true

require 'yaml'
$VERBOSE = true

if ENV.fetch('COVERAGE', 'f').start_with? 't'
  require 'simplecov'
  SimpleCov.start
end

require 'rubocop-ast'
if ENV['MODERNIZE']
  RuboCop::AST::Builder.modernize
  RuboCop::AST::Builder.emit_forward_arg = false # inverse of default
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

# ...
module DefaultRubyVersion
  extend RSpec::SharedContext

  let(:ruby_version) { 2.4 }
end

module RuboCop
  module AST
    # patch class
    class ProcessedSource
      attr_accessor :node
    end
  end
end

# ...
module ParseSourceHelper
  def parse_source(source)
    lookup = nil
    ruby = source.gsub(/>>(.*)<</) { lookup = Regexp.last_match(1).strip }
    source = RuboCop::AST::ProcessedSource.new(ruby, ruby_version, nil)
    source.node = if lookup
                    source.ast.each_node.find(
                      -> { raise "No node corresponds to source '#{lookup}'" }
                    ) { |node| node.source == lookup }
                  else
                    source.ast
                  end
    source
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
