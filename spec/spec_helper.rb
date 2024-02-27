# frozen_string_literal: true

require 'yaml'
$VERBOSE = true

if ENV.fetch('COVERAGE', 'f').start_with? 't'
  require 'simplecov'
  SimpleCov.start
end

ENV['RUBOCOP_DEBUG'] = 't'

require 'rubocop-ast'
if ENV['MODERNIZE']
  RuboCop::AST::Builder.modernize
  RuboCop::AST::Builder.emit_forward_arg = false # inverse of default
  if RuboCop::AST::Builder.respond_to?(:emit_match_pattern=)
    RuboCop::AST::Builder.emit_match_pattern = false # inverse of default
  end
end

RSpec.shared_context 'ruby 2.3', :ruby23 do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 2.3 }
end

RSpec.shared_context 'ruby 2.4', :ruby24 do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 2.4 }
end

RSpec.shared_context 'ruby 2.5', :ruby25 do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 2.5 }
end

RSpec.shared_context 'ruby 2.6', :ruby26 do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 2.6 }
end

RSpec.shared_context 'ruby 2.7', :ruby27 do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 2.7 }
end

RSpec.shared_context 'ruby 3.0', :ruby30 do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 3.0 }
end

RSpec.shared_context 'ruby 3.1', :ruby31 do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 3.1 }
end

RSpec.shared_context 'ruby 3.2', :ruby32 do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 3.2 }
end

RSpec.shared_context 'ruby 3.3', :ruby33 do
  let(:ruby_version) { 3.3 }
end

RSpec.shared_context 'ruby 3.4', :ruby34 do
  let(:ruby_version) { 3.4 }
end

# ...
module DefaultRubyVersion
  extend RSpec::SharedContext

  # The minimum version Prism can parse is 3.3.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 2.4 }
end

module DefaultParserEngine
  extend RSpec::SharedContext

  let(:parser_engine) { ENV.fetch('PARSER_ENGINE', :parser_whitequark).to_sym }
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
    source = RuboCop::AST::ProcessedSource.new(ruby, ruby_version, nil, parser_engine: parser_engine)
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
  config.include DefaultParserEngine

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

  config.filter_run_excluding broken_on: :prism if ENV['PARSER_ENGINE'] == 'parser_prism'

  config.order = :random
  Kernel.srand config.seed
end
