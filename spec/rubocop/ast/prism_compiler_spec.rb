# frozen_string_literal: true

require_relative '../../../tasks/tree_diff'

RSpec.describe RuboCop::AST::PrismCompiler, :parser_gem, if: Prism::VERSION.to_i >= 2 do
  def parse(source, engine, ruby_version = 3.4)
    RuboCop::AST::ProcessedSource.new(source, ruby_version, parser_engine: engine)
  end

  # The translation layer is the reference: the native builder has to produce
  # the same node types, node classes, children and source maps.
  def difference(source, ruby_version = 3.4)
    expected = parse(source, :parser_prism, ruby_version)
    actual = parse(source, :prism, ruby_version)
    raise "invalid source: #{expected.diagnostics.map(&:render).join}" unless expected.ast
    raise actual.parser_error if actual.parser_error

    TreeDiff.new.call(expected.ast, actual.ast)
  end

  Dir["#{__dir__}/fixtures/prism_compiler/*.rb"].sort.each do |fixture|
    it "builds the same tree as the translation layer for #{File.basename(fixture, '.rb').tr('_', ' ')}" do
      expect(difference(File.read(fixture))).to be_nil
    end
  end

  it 'builds the same tree as the translation layer for the Ruby 3.3 syntax' do
    expect(difference(<<~SOURCE, 3.3)).to be_nil
      foo { _1 + it }
      a = [1, *b]
      def c(...) = d(...)
    SOURCE
  end

  # `parser` reads these as negative literals, Prism as calls to `-@`.
  it 'builds the same tree as the translation layer for a minus separated from a number' do
    expect(difference(<<~SOURCE)).to be_nil
      a = - 1
      b = - 2.5
      - 3r
      - 4i
      -
      5
      - 6.abs
    SOURCE
  end

  it 'builds the same tree as the translation layer for a `nil` block parameter' do
    expect(difference(<<~SOURCE, 4.1)).to be_nil
      foo { |&nil| }
      ->(a, &nil) {}
    SOURCE
  end

  # The translation layer of Prism 2.1 raises for this one.
  it 'builds the tree for a method with a `nil` block parameter' do
    ast = parse('def foo(&nil) = bar', :prism, 4.1).ast

    expect(ast.first_argument.type).to eq(:blocknilarg)
    expect(ast.first_argument.source).to eq('&nil')
    expect(ast.body.source).to eq('bar')
  end

  it 'builds the same tree as the translation layer for the library sources' do
    Dir[File.expand_path('../../../lib/**/*.rb', __dir__)].each do |path|
      expect(difference(File.read(path))).to be_nil, -> { "#{path}: #{difference(File.read(path))}" }
    end
  end

  it 'builds the tree from a prism result that was parsed beforehand' do
    source = 'foo.bar(1)'
    processed_source = RuboCop::AST::ProcessedSource.new(
      source, 3.4, parser_engine: :prism, prism_result: Prism.parse_lex(source)
    )

    expect(processed_source.parser_engine).to eq(:prism)
    expect(processed_source.ast).to eq(parse(source, :parser_prism).ast)
  end

  it 'reports a regexp that cannot be compiled' do
    processed_source = parse('/\p{Foo}/ =~ foo', :prism)

    expect(processed_source.diagnostics.map(&:reason)).to eq([:invalid_regexp])
    expect(processed_source).not_to be_valid_syntax
  end

  it 'reports a regexp that cannot be compiled when it only interpolates string literals' do
    ['/#{"["}/', '/#{}\xff/u', '/a#{"b"; "("}/'].each do |source|
      reported = parse(source, :prism).diagnostics.map { |diagnostic| [diagnostic.reason, diagnostic.message] }
      expected = parse(source, :parser_prism).diagnostics.map { |diagnostic| [diagnostic.reason, diagnostic.message] }

      expect(reported.map(&:first)).to include(:invalid_regexp), source
      expect(reported).to eq(expected), source
    end
  end

  it 'does not check a regexp that interpolates anything else' do
    ['/#{foo}[/', '/#{"#{"("}"}/', '/#{1}(/'].each do |source|
      expect(parse(source, :prism)).to be_valid_syntax, source
    end
  end

  it 'reports duplicate hash keys' do
    processed_source = parse('{ a: 1, a: 2 }', :prism)

    expect(processed_source.diagnostics.map(&:reason)).to eq([:duplicate_hash_key])
    expect(processed_source).to be_valid_syntax
  end
end
