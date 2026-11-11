# frozen_string_literal: true

require 'open3'

RSpec.describe 'Loading of the `parser` gem' do # rubocop:disable RSpec/DescribeClass -- about load order, not a class
  # Under Bundler the Gemfile is evaluated again in the child process and may
  # print something, so the output only counts from the marker on.
  def run(code)
    lib = File.expand_path('../../../lib', __dir__)
    script = "require 'rubocop-ast'\nputs 'OUTPUT:'\n#{code}"
    output, status = Open3.capture2e(RbConfig.ruby, "-I#{lib}", '-e', script)
    raise output unless status.success?

    output.split("OUTPUT:\n", 2).last
  end

  let(:parsers_loaded) { 'Parser.const_defined?(:Base, false)' }

  it 'loads the source layer, but not the parsers' do
    expect(run(<<~RUBY)).to eq("true\nfalse\n")
      puts [Parser::Source::Range, Parser::Source::TreeRewriter, Parser::Diagnostic::Engine].all?
      puts #{parsers_loaded}
    RUBY
  end

  it 'does not load the parsers for the `prism` parser engine', if: Prism::VERSION.to_i >= 2 do
    expect(run(<<~RUBY)).to eq("s(:send, nil, :foo)\n1\nfalse\nfalse\n")
      processed_source = RuboCop::AST::ProcessedSource.new('foo', 3.4, parser_engine: :prism)
      p processed_source.ast
      puts processed_source.tokens.size
      puts #{parsers_loaded}
      puts $LOADED_FEATURES.any? { |feature| feature.include?('prism/translation') }
    RUBY
  end

  %i[parser_whitequark parser_prism].each do |engine|
    it "loads the parsers for the `#{engine}` parser engine" do
      expect(run(<<~RUBY)).to eq("s(:send, nil, :foo)\ntrue\n")
        p RuboCop::AST::ProcessedSource.new('foo', 3.3, parser_engine: :#{engine}).ast
        puts #{parsers_loaded}
      RUBY
    end
  end

  it 'loads the rest of `parser` when one of its constants is referenced' do
    expect(run(<<~RUBY)).to eq("Parser::Base\nParser::AST::Processor\nParser::Source::Rewriter\n")
      puts Parser::Base, Parser::AST::Processor, Parser::Source::Rewriter
    RUBY
  end

  it 'raises for a constant that `parser` does not have' do
    expect(run(<<~RUBY)).to eq("NameError\nNameError\n")
      puts [Parser, Parser::Source].map { |mod| mod::Missing rescue $!.class }
    RUBY
  end

  it 'works with a builder that was created before the parser was required' do
    expect(run(<<~RUBY)).to eq("s(:send, nil, :foo)\n")
      builder = RuboCop::AST::Builder.new
      require 'parser/ruby33'
      p Parser::Ruby33.new(builder).parse(Parser::Source::Buffer.new('(string)', source: 'foo'))
    RUBY
  end
end
