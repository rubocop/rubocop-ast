# frozen_string_literal: true

require 'open3'

RSpec.describe 'Loading of the `parser` gem' do # rubocop:disable RSpec/DescribeClass -- about load order, not a class
  # Under Bundler the Gemfile is evaluated again in the child process and may
  # print something, so the output only counts from the marker on.
  def run(code, *options)
    lib = File.expand_path('../../../lib', __dir__)
    script = "require 'rubocop-ast'\nputs 'OUTPUT:'\n#{code}"
    output, status = Open3.capture2e(RbConfig.ruby, "-I#{lib}", *options, '-e', script)
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
    it "loads the parsers for the `#{engine}` parser engine", :parser_gem do
      expect(run(<<~RUBY)).to eq("s(:send, nil, :foo)\ntrue\n")
        p RuboCop::AST::ProcessedSource.new('foo', 3.3, parser_engine: :#{engine}).ast
        puts #{parsers_loaded}
      RUBY
    end
  end

  it 'loads the rest of `parser` when one of its constants is referenced', :parser_gem do
    expect(run(<<~RUBY)).to eq("Parser::Base\nParser::AST::Processor\nParser::Source::Rewriter\n")
      puts Parser::Base, Parser::AST::Processor, Parser::Source::Rewriter
    RUBY
  end

  it 'raises for a constant that `parser` does not have' do
    expect(run(<<~RUBY)).to eq("NameError\nNameError\n")
      puts [Parser, Parser::Source].map { |mod| mod::Missing rescue $!.class }
    RUBY
  end

  it 'works with a builder that was created before the parser was required', :parser_gem do
    expect(run(<<~RUBY)).to eq("s(:send, nil, :foo)\n")
      builder = RuboCop::AST::Builder.new
      require 'parser/ruby33'
      p Parser::Ruby33.new(builder).parse(Parser::Source::Buffer.new('(string)', source: 'foo'))
    RUBY
  end

  context 'when the `parser` gem is not installed' do
    def run(code)
      super(code, "-r#{File.expand_path('../../support/hide_parser', __dir__)}")
    end

    let(:vendor_dir) { RuboCop::AST::ParserSource::VENDOR_DIR }

    it 'loads the copy of the source layer that ships with this gem' do
      expect(run(<<~RUBY)).to eq("true\n#{vendor_dir}\n")
        puts RuboCop::AST::ParserSource.vendored?
        puts File.dirname(File.dirname(Parser::Source.const_source_location(:Range).first))
      RUBY
    end

    it 'parses and rewrites with the `prism` parser engine', if: Prism::VERSION.to_i >= 2 do
      expect(run(<<~RUBY)).to eq("s(:send, nil, :foo)\nprism\nbar\n")
        processed_source = RuboCop::AST::ProcessedSource.new('foo', 3.4)
        p processed_source.ast
        puts processed_source.parser_engine
        rewriter = Parser::Source::TreeRewriter.new(processed_source.buffer)
        puts rewriter.replace(processed_source.ast.source_range, 'bar').process
      RUBY
    end

    %i[parser_whitequark parser_prism].each do |engine|
      it "raises for the `#{engine}` parser engine" do
        expect(run(<<~RUBY)).to eq("The `#{engine}` parser engine needs the `parser` gem.\n")
          begin
            RuboCop::AST::ProcessedSource.new('foo', 3.3, parser_engine: :#{engine})
          rescue LoadError => e
            puts e.message[0..e.message.index('.')]
          end
        RUBY
      end
    end

    it 'raises for a constant of `parser` that is not part of the source layer' do
      expect(run(<<~RUBY)).to eq("NameError\nNameError\n")
        puts [Parser, Parser::Source].map { |mod| mod::Base rescue $!.class }
      RUBY
    end
  end

  # The copy has to be refreshed with `rake vendor_parser` when this fails.
  it 'ships a copy that matches the `parser` gem it was taken from', :parser_gem do
    vendored_version = File.read(File.join(RuboCop::AST::ParserSource::VENDOR_DIR, 'version.rb'))
    skip 'another version of `parser` is installed' unless vendored_version.include?(Parser::VERSION)

    gem_dir = File.join(Gem.loaded_specs.fetch('parser').full_gem_path, 'lib', 'parser')
    changed = RuboCop::AST::ParserSource::FILES.reject do |file|
      File.read(File.join(gem_dir, "#{file}.rb")) ==
        File.read(File.join(RuboCop::AST::ParserSource::VENDOR_DIR, "#{file}.rb"))
    end

    expect(changed).to be_empty
  end
end
