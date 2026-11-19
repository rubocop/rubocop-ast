foo; foo(); foo 1; foo.bar; foo&.bar; foo::bar; foo.(1); foo[1]; foo[1] = 2; foo.bar = 1
foo&.bar = 1; !foo; not foo; not(foo); -foo; +foo; ~foo; foo + 1; foo == 1; foo =~ /a/
/(?<a>b)/ =~ foo; foo !~ /a/; foo(*a, **b, &c); foo(a: 1, 'b': 2, "c#{d}": 3, e => f)
foo { }; foo { |a| }; foo { |a, (b, c), *d, e: 1, **f, &g; h| }; foo do |a,| end
foo { _1 + _2 }; foo { it }; -> { }; ->(a, b = 1) { a }; -> do end; lambda { |x| x }
super; super(); super(1) { }; super { }; yield; yield(1); yield 1, 2
foo.bar += 1; foo.bar ||= 1; foo&.bar &&= 1; foo[1] += 1; foo[1] ||= 2; foo[1, 2] &&= 3
a, b = 1, 2; a, (b, *c), d = e; *a, b = c; a.b, c[1], @d, $e, F, G::H = i; (a, b), c = d
