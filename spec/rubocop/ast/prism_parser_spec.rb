# frozen_string_literal: true

RSpec.describe RuboCop::AST::PrismParser, if: Prism::VERSION.to_i >= 2 do
  def parse(source, engine, ruby_version = 3.4)
    RuboCop::AST::ProcessedSource.new(source, ruby_version, parser_engine: engine)
  end

  def tokens(processed_source)
    processed_source.tokens.map do |token|
      [token.type, token.text, token.text.encoding, token.begin_pos, token.end_pos]
    end
  end

  def diagnostics(processed_source)
    processed_source.diagnostics.map do |diagnostic|
      [diagnostic.level, diagnostic.reason, diagnostic.message, diagnostic.location.to_a]
    end
  end

  def results(processed_source)
    {
      tokens: tokens(processed_source),
      comments: processed_source.comments.map { |comment| [comment.text, comment.loc.expression.to_a] },
      diagnostics: diagnostics(processed_source),
      valid_syntax: processed_source.valid_syntax?,
      parser_error: processed_source.parser_error
    }
  end

  # The translation layer is the reference for everything but the AST as well.
  def expect_same_results(source, ruby_version = 3.4)
    expected = parse(source, :parser_prism, ruby_version)
    actual = parse(source, :prism, ruby_version)

    expect(results(actual)).to eq(results(expected))
  end

  it 'returns the same tokens and comments as the translation layer' do
    expect_same_results(<<~'RUBY')
      # frozen_string_literal: true
      foo(1, :a, "b#{c}d", %w[e f], <<~G) { |h| h.i -> (j) do end } # k
        l #{m}
      G
      =begin
      n
      =end
      o = { p: 1, 'q': 2 }; r ? s : t; u&.v ||= /w/x; y[1] = -2.5; `z`
    RUBY
  end

  it 'returns the same tokens and comments as the translation layer for a multibyte source' do
    expect_same_results("# é\nfoo('é', :è) { |ü| \"\#{ü}ö\" } # ß\n")
  end

  it 'returns the same tokens, comments and diagnostics for the library sources' do
    Dir[File.expand_path('../../../lib/**/*.rb', __dir__)].each do |path|
      expect_same_results(File.read(path))
    end
  end

  it 'reports the same warnings as the translation layer' do
    expect_same_results("foo *bar\nfoo -1\nfoo /bar/\nfoo &bar\nfoo **bar\n")

    expect(parse('foo *bar', :prism).diagnostics.map(&:reason)).to eq([:ambiguous_prefix])
  end

  it 'reports the same syntax errors as the translation layer' do
    [
      'def foo(a, a); end', 'class Foo; def bar; class Baz; end; end; end', 'foo(', '1 +',
      'def foo; Bar = 1; end', '@', '"foo', 'foo { |a| _1 }', "begin; else; end\n", 'def foo=(a) = 1'
    ].each do |source|
      expect_same_results(source)
      expect(parse(source, :prism)).not_to be_valid_syntax
    end
  end

  it 'reports an error that `parser` does not know about with the message of Prism' do
    diagnostic = parse('1 +', :prism).diagnostics.first

    expect(diagnostic).to be_a(RuboCop::AST::PrismDiagnostic)
    expect(diagnostic.level).to eq(:error)
    expect(diagnostic.message).to eq(Prism.parse('1 +').errors.first.message)
  end

  # Every error is fatal on the other Ruby implementations, which leaves
  # nothing but the diagnostics.
  it 'has no AST for an invalid source, but has its comments', if: RUBY_ENGINE == 'ruby' do
    processed_source = parse("foo( # bar\n", :prism)

    expect(processed_source.ast).to be_nil
    expect(processed_source.comments.map(&:text)).to eq(['# bar'])
  end

  it 'accepts a Ruby version that is an integer' do
    expect(parse('foo', :prism, 4).ast).to eq(parse('foo', :parser_prism, 4).ast)
  end

  it 'does not accept a Ruby version that Prism cannot parse' do
    expect { parse('foo', :prism, 3.2) }
      .to raise_error(ArgumentError, /supports target Ruby versions 3.3 and above with Prism/)
  end

  # Prism 2.0 has these two wrong in its translation layer, so `parser` is
  # the reference.
  it 'splits a string with a line break and an escaped newline like `parser` does' do
    source = %("a\nb\\nc")

    expect(parse(source, :prism).ast).to eq(parse(source, :parser_whitequark).ast)
  end

  it 'splits a quoted hash key with a line break like `parser` does' do
    source = %({ "a\nb": 1, "": 2 })

    expect(parse(source, :prism).ast).to eq(parse(source, :parser_whitequark).ast)
  end
end
