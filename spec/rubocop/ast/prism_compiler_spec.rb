# frozen_string_literal: true

require_relative '../../../tasks/tree_diff'

RSpec.describe RuboCop::AST::PrismCompiler, if: Prism::VERSION.to_i >= 2 do
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

  {
    'literals' => <<~'RUBY',
      [1, -2, +3, 1.5, -1.5, 2r, -3r, 4i, -5i, 1ri, nil, true, false, self]
      [:a, :"b", :"c#{d}", :'e', %s(f), ?g, "h", 'i', "j#{k}l", "", %q(), %(), `ls`, `ls #{m}`]
      [%w[a b], %W[a#{b} c], %i[a b], %I[a#{b} c], 1..2, 1...2, (1..), (..2), __FILE__, __LINE__]
      [__ENCODING__, $a, $1, $~, @b, @@c, D, ::E, F::G, /h/, /i#{j}/mix, %r{k}o, "é", :é]
    RUBY
    'multiline strings' => <<~'RUBY',
      a = "foo
      bar\nbaz \
      qux"
      b = 'foo
      bar'
      c = %w[a\
      b c
      d]
      d = "a" "b" \
        "c#{d}"
      e = /foo
      bar/x
    RUBY
    'heredocs' => <<~'RUBY',
      foo(<<~A, <<-B, <<C)
        a #{b}
          c \
        d
      A
        plain
        B
      raw
      C
      x = <<~'D'
        #{not} interpolated
      D
      y = <<~E
        #{first}
        second
      E
      z = <<~`F`
        echo #{a}
      F
    RUBY
    'calls' => <<~'RUBY',
      foo; foo(); foo 1; foo.bar; foo&.bar; foo::bar; foo.(1); foo[1]; foo[1] = 2; foo.bar = 1
      foo&.bar = 1; !foo; not foo; not(foo); -foo; +foo; ~foo; foo + 1; foo == 1; foo =~ /a/
      /(?<a>b)/ =~ foo; foo !~ /a/; foo(*a, **b, &c); foo(a: 1, 'b': 2, "c#{d}": 3, e => f)
      foo { }; foo { |a| }; foo { |a, (b, c), *d, e: 1, **f, &g; h| }; foo do |a,| end
      foo { _1 + _2 }; foo { it }; -> { }; ->(a, b = 1) { a }; -> do end; lambda { |x| x }
      super; super(); super(1) { }; super { }; yield; yield(1); yield 1, 2
      foo.bar += 1; foo.bar ||= 1; foo&.bar &&= 1; foo[1] += 1; foo[1] ||= 2; foo[1, 2] &&= 3
      a, b = 1, 2; a, (b, *c), d = e; *a, b = c; a.b, c[1], @d, $e, F, G::H = i; (a, b), c = d
    RUBY
    'assignments' => <<~RUBY,
      a = 1; a += 1; a ||= 1; a &&= 1; @a = 1; @a += 1; @a ||= 1; @a &&= 1
      @@a = 1; @@a += 1; @@a ||= 1; @@a &&= 1; $a = 1; $a += 1; $a ||= 1; $a &&= 1
      A = 1; A += 1; A ||= 1; A &&= 1; A::B = 1; A::B += 1; ::C ||= 1; A::B &&= 1
    RUBY
    'definitions' => <<~RUBY,
      def a; end
      def b(c, d = 1, *e, f, g:, h: 2, **i, &j) = c
      def self.k(...) = l(...)
      def m(*, **, &) = n(*, **, &)
      def (o).p; end
      def !@; end
      def ==(other) end
      def q(**nil); end
      class R < S; def t; end; end
      class << self; end
      module U::V; end
      alias a b
      alias $a $b
      undef a, :b
      BEGIN { a }
      END { b }
    RUBY
    'control flow' => <<~RUBY,
      if a then b elsif c then d else e end
      if a; b; end
      unless a then b else c end
      a ? b : c
      b if a
      b unless a
      while a do b end
      until a; b; end
      b while a
      begin; b; end until a
      for a, b in c do d end
      for a in b; end
      case a when 1, 2 then b when 3; c else d end
      case when a then b end
      if /a/ then b end
      if a..b then c end
      if (a and !/b/) || c...d then e end
      foo { return; return 1; break 1, 2; next; redo }
      defined?(a); defined? b; a and b; a or b; a && b; a || b
    RUBY
    'exceptions' => <<~RUBY,
      begin; a; rescue; b; end
      begin; a; rescue B, C => d then e; rescue F; g; else h; ensure i; end
      begin; a; rescue; retry; end
      begin; ensure; end
      def a; b; rescue => @c; d; ensure; e; end
      foo do a rescue b end
      foo do a; rescue; b; ensure; c; end
      a rescue b
      a = b rescue c
    RUBY
    'pattern matching' => <<~RUBY
      case a
      in 1 | 2 then b
      in [Integer => c, *d] if e then f
      in [a,] unless g then h
      in {i:, "j": k, **l} then m
      in {n: 1, **nil}
      in O(1) | Q[2] | S(t: 3) | U() then v
      in O(p) then q
      in R[s] then t
      in [*, w, *x]
      in ^a then z
      in ^(a + b)
      in nil
      else c
      end
      a in [b, *]
      a => {b:}
      case a; in b; else; end
    RUBY
  }.each do |name, source|
    it "builds the same tree as the translation layer for #{name}" do
      expect(difference(source)).to be_nil
    end
  end

  it 'builds the same tree as the translation layer for a multibyte source' do
    expect(difference("# é\nfoo('é', :è) { |ü| \"\#{ü}ö\" }\n")).to be_nil
  end

  it 'builds the same tree as the translation layer for the Ruby 3.3 syntax' do
    expect(difference('foo { _1 + it }; a = [1, *b]; def c(...) = d(...)', 3.3)).to be_nil
  end

  # `parser` reads these as negative literals, Prism as calls to `-@`.
  it 'builds the same tree as the translation layer for a minus separated from a number' do
    expect(difference("a = - 1; b = - 2.5; - 3r; - 4i; -\n5; - 6.abs")).to be_nil
  end

  it 'builds the same tree as the translation layer for a `nil` block parameter' do
    expect(difference('foo { |&nil| }; ->(a, &nil) {}', 4.1)).to be_nil
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

  it 'reports duplicate hash keys' do
    processed_source = parse('{ a: 1, a: 2 }', :prism)

    expect(processed_source.diagnostics.map(&:reason)).to eq([:duplicate_hash_key])
    expect(processed_source).to be_valid_syntax
  end
end
