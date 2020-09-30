# Extracted from `parser` gem.
# Add the following code at the beginning of `def assert_parses`:
#
#    File.open('./out.rb', 'a+') do |f|
#      f << code << "\n\n#----\n" if versions.include? '2.7'
#    end

alias $a $b

#----
alias $a $+

#----
bar unless foo

#----
foo[1, 2]

#----
Foo = 10

#----
!foo

#----
case foo; in A then true; end

#----
case foo; in A::B then true; end

#----
case foo; in ::A then true; end

#----
()

#----
begin end

#----
foo[:baz => 1,]

#----
Bar::Foo = 10

#----
foo += meth rescue bar

#----
def foo(_, _); end

#----
def foo(_a, _a); end

#----
def a b:
return
end

#----
o = {
a:
1
}

#----
a b{c d}, :e do end

#----
a b{c(d)}, :e do end

#----
a b(c d), :e do end

#----
a b(c(d)), :e do end

#----
a b{c d}, 1 do end

#----
a b{c(d)}, 1 do end

#----
a b(c d), 1 do end

#----
a b(c(d)), 1 do end

#----
a b{c d}, 1.0 do end

#----
a b{c(d)}, 1.0 do end

#----
a b(c d), 1.0 do end

#----
a b(c(d)), 1.0 do end

#----
a b{c d}, 1.0r do end

#----
a b{c(d)}, 1.0r do end

#----
a b(c d), 1.0r do end

#----
a b(c(d)), 1.0r do end

#----
a b{c d}, 1.0i do end

#----
a b{c(d)}, 1.0i do end

#----
a b(c d), 1.0i do end

#----
a b(c(d)), 1.0i do end

#----
td (1_500).toString(); td.num do; end

#----
-> do rescue; end

#----
bar if foo

#----
yield(foo)

#----
yield foo

#----
yield()

#----
yield

#----
next(foo)

#----
next foo

#----
next()

#----
next

#----
1...2

#----
case foo; when 1, *baz; bar; when *foo; end

#----
def foo(...); bar(...); end

#----
def foo(...); super(...); end

#----
def foo(...); end

#----
super(foo)

#----
super foo

#----
super()

#----
desc "foo" do end

#----
next fun foo do end

#----
def f(foo); end

#----
def f(foo, bar); end

#----
%i[]

#----
%I()

#----
[1, 2]

#----
{a: if true then 42 end}

#----
def f(*foo); end

#----
<<HERE
foo
bar
HERE

#----
<<'HERE'
foo
bar
HERE

#----
<<`HERE`
foo
bar
HERE

#----
->(a; foo, bar) { }

#----
42

#----
+42

#----
-42

#----
module ::Foo; end

#----
module Bar::Foo; end

#----
foo&.bar {}

#----
fun(f bar)

#----
begin meth end while foo

#----
case foo; in 1; end

#----
case foo; in ->{ 42 } then true; end

#----
begin; meth; rescue; baz; else foo; ensure; bar end

#----
super

#----
m "#{[]}"

#----
foo[1, 2] = 3

#----
foo + 1

#----
foo - 1

#----
foo * 1

#----
foo / 1

#----
foo % 1

#----
foo ** 1

#----
foo | 1

#----
foo ^ 1

#----
foo & 1

#----
foo <=> 1

#----
foo < 1

#----
foo <= 1

#----
foo > 1

#----
foo >= 1

#----
foo == 1

#----
foo != 1

#----
foo === 1

#----
foo =~ 1

#----
foo !~ 1

#----
foo << 1

#----
foo >> 1

#----
tap (proc do end)

#----
def foo
=begin
=end
end

#----
:foo

#----
:'foo'

#----
fun(*bar)

#----
fun(*bar, &baz)

#----
m { _1 + _9 }

#----
m do _1 + _9 end

#----
-> { _1 + _9}

#----
-> do _1 + _9 end

#----
case foo; when 'bar', 'baz'; bar; end

#----
case foo; in x, then nil; end

#----
case foo; in *x then nil; end

#----
case foo; in * then nil; end

#----
case foo; in x, y then nil; end

#----
case foo; in x, y, then nil; end

#----
case foo; in x, *y, z then nil; end

#----
case foo; in *x, y, z then nil; end

#----
case foo; in 1, "a", [], {} then nil; end

#----
for a in foo do p a; end

#----
for a in foo; p a; end

#----
until foo do meth end

#----
until foo; meth end

#----
def self.foo; end

#----
def self::foo; end

#----
def (foo).foo; end

#----
def String.foo; end

#----
def String::foo; end

#----
self::A, foo = foo

#----
::A, foo = foo

#----
fun(&bar)

#----
foo[bar, :baz => 1,]

#----
{ 1 => 2 }

#----
{ 1 => 2, :foo => "bar" }

#----
m def x(); end; 1.tap do end

#----
true

#----
case foo; when 'bar'; bar; end

#----
def f(foo:); end

#----
f{ |a| }

#----
redo

#----
__FILE__

#----
42r

#----
42.1r

#----
def f a, o=1, *r, &b; end

#----
def f a, o=1, *r, p, &b; end

#----
def f a, o=1, &b; end

#----
def f a, o=1, p, &b; end

#----
def f a, *r, &b; end

#----
def f a, *r, p, &b; end

#----
def f a, &b; end

#----
def f o=1, *r, &b; end

#----
def f o=1, *r, p, &b; end

#----
def f o=1, &b; end

#----
def f o=1, p, &b; end

#----
def f *r, &b; end

#----
def f *r, p, &b; end

#----
def f &b; end

#----
def f ; end

#----
{ }

#----
p <<~E "  y"
  x
E

#----
class A; _1; end

#----
module A; _1; end

#----
class << foo; _1; end

#----
def self.m; _1; end

#----
_1

#----
case foo; in [x] then nil; end

#----
case foo; in [x,] then nil; end

#----
case foo; in [x, y] then true; end

#----
case foo; in [x, y,] then true; end

#----
case foo; in [x, y, *] then true; end

#----
case foo; in [x, y, *z] then true; end

#----
case foo; in [x, *y, z] then true; end

#----
case foo; in [x, *, y] then true; end

#----
case foo; in [*x, y] then true; end

#----
case foo; in [*, x] then true; end

#----
case foo; in 1 | 2 then true; end

#----
a += 1

#----
@a |= 1

#----
@@var |= 10

#----
def a; @@var |= 10; end

#----
def foo() a:b end

#----
def foo
 a:b end

#----
f { || a:b }

#----
fun (f bar)

#----
__ENCODING__

#----
__ENCODING__

#----
[ 1 => 2 ]

#----
[ 1, 2 => 3 ]

#----
'a\
b'

#----
<<-'HERE'
a\
b
HERE

#----
%q{a\
b}

#----
"a\
b"

#----
<<-"HERE"
a\
b
HERE

#----
%{a\
b}

#----
%Q{a\
b}

#----
%w{a\
b}

#----
%W{a\
b}

#----
%i{a\
b}

#----
%I{a\
b}

#----
:'a\
b'

#----
%s{a\
b}

#----
:"a\
b"

#----
/a\
b/

#----
%r{a\
b}

#----
%x{a\
b}

#----
`a\
b`

#----
<<-`HERE`
a\
b
HERE

#----
->(scope) {}; scope

#----
while class Foo; tap do end; end; break; end

#----
while class Foo a = tap do end; end; break; end

#----
while class << self; tap do end; end; break; end

#----
while class << self; a = tap do end; end; break; end

#----
meth until foo

#----
break fun foo do end

#----
foo

#----
BEGIN { 1 }

#----
unless foo then bar; else baz; end

#----
unless foo; bar; else baz; end

#----
proc {_1 = nil}

#----
begin ensure end

#----
case 1; in 2; 3; else; 4; end

#----
case foo; in x if true; nil; end

#----
case foo; in x unless true; nil; end

#----
<<~FOO
  baz\
  qux
FOO

#----
foo = raise(bar) rescue nil

#----
foo += raise(bar) rescue nil

#----
foo[0] += raise(bar) rescue nil

#----
foo.m += raise(bar) rescue nil

#----
foo::m += raise(bar) rescue nil

#----
foo.C += raise(bar) rescue nil

#----
foo::C ||= raise(bar) rescue nil

#----
foo = raise bar rescue nil

#----
foo += raise bar rescue nil

#----
foo[0] += raise bar rescue nil

#----
foo.m += raise bar rescue nil

#----
foo::m += raise bar rescue nil

#----
foo.C += raise bar rescue nil

#----
foo::C ||= raise bar rescue nil

#----
p p{p(p);p p}, tap do end

#----
begin meth end until foo

#----
m1 :k => m2 do; m3() do end; end

#----
__LINE__

#----
if (bar); foo; end

#----
foo.a = 1

#----
foo::a = 1

#----
foo.A = 1

#----
foo::A = 1

#----
$10

#----
1 in [a]; a

#----
true ? 1.tap do |n| p n end : 0

#----
false ? raise {} : tap {}

#----
false ? raise do end : tap do end

#----
Bar::Foo

#----
a&.b = 1

#----
break(foo)

#----
break foo

#----
break()

#----
break

#----
if foo..bar; end

#----
!(foo..bar)

#----
Foo

#----
END { 1 }

#----
class Foo < Bar; end

#----
begin; meth; rescue Exception; bar; end

#----
fun { }

#----
fun() { }

#----
fun(1) { }

#----
fun do end

#----
case foo; when 'bar' then bar; end

#----
begin; meth; rescue foo => ex; bar; end

#----
@foo

#----
if foo
then bar end

#----
fun (1).to_i

#----
$var = 10

#----
/\xa8/n =~ ""

#----
while not (true) do end

#----
foo, bar = 1, 2

#----
(foo, bar) = 1, 2

#----
foo, bar, baz = 1, 2

#----
proc {_1 = nil}

#----
_2 = 1

#----
proc {|_3|}

#----
def x(_4) end

#----
def _5; end

#----
def self._6; end

#----
meth rescue bar

#----
self.a, self[1, 2] = foo

#----
self::a, foo = foo

#----
self.A, foo = foo

#----
foo.a += m foo

#----
foo::a += m foo

#----
foo.A += m foo

#----
foo::A += m foo

#----
m { |foo| }

#----
m { |(foo, bar)| }

#----
module Foo; end

#----
f{  }

#----
f{ | | }

#----
f{ |;a| }

#----
f{ |;
a
| }

#----
f{ || }

#----
f{ |a| }

#----
f{ |a, c| }

#----
f{ |a,| }

#----
f{ |a, &b| }

#----
f{ |a, *s, &b| }

#----
f{ |a, *, &b| }

#----
f{ |a, *s| }

#----
f{ |a, *| }

#----
f{ |*s, &b| }

#----
f{ |*, &b| }

#----
f{ |*s| }

#----
f{ |*| }

#----
f{ |&b| }

#----
f{ |a, o=1, o1=2, *r, &b| }

#----
f{ |a, o=1, *r, p, &b| }

#----
f{ |a, o=1, &b| }

#----
f{ |a, o=1, p, &b| }

#----
f{ |a, *r, p, &b| }

#----
f{ |o=1, *r, &b| }

#----
f{ |o=1, *r, p, &b| }

#----
f{ |o=1, &b| }

#----
f{ |o=1, p, &b| }

#----
f{ |*r, p, &b| }

#----
assert dogs

#----
assert do: true

#----
f x: -> do meth do end end

#----
foo "#{(1+1).to_i}" do; end

#----
alias :foo bar

#----
..100

#----
...100

#----
case foo; in ^foo then nil; end

#----
for a, b in foo; p a, b; end

#----
t=1;(foo)?t:T

#----
foo[1, 2]

#----
f{ |a| }

#----
!m foo

#----
fun(:foo => 1)

#----
fun(:foo => 1, &baz)

#----
%W[foo #{bar}]

#----
%W[foo #{bar}foo#@baz]

#----
fun (1)

#----
%w[]

#----
%W()

#----
`foobar`

#----
case foo; in self then true; end

#----
a, (b, c) = foo

#----
((b, )) = foo

#----
class A < B
end

#----
bar def foo; self.each do end end

#----
case foo; in "a": then true; end

#----
case foo; in "#{ 'a' }": then true; end

#----
case foo; in "#{ %q{a} }": then true; end

#----
case foo; in "#{ %Q{a} }": then true; end

#----
case foo; in "a": 1 then true; end

#----
case foo; in "#{ 'a' }": 1 then true; end

#----
case foo; in "#{ %q{a} }": 1 then true; end

#----
case foo; in "#{ %Q{a} }": 1 then true; end

#----
a&.b &&= 1

#----
"#{-> foo {}}"

#----
-foo

#----
+foo

#----
~foo

#----
meth while foo

#----
$+

#----
[1, *foo, 2]

#----
[1, *foo]

#----
[*foo]

#----
f{ |foo: 1, bar: 2, **baz, &b| }

#----
f{ |foo: 1, &b| }

#----
f{ |**baz, &b| }

#----
if foo...bar; end

#----
!(foo...bar)

#----
fun(foo, *bar)

#----
fun(foo, *bar, &baz)

#----
foo or bar

#----
foo || bar

#----
f{ |foo:| }

#----
1.33

#----
-1.33

#----
foo[1, 2] = 3

#----
def f foo = 1; end

#----
def f(foo=1, bar=2); end

#----
case foo; in A(1, 2) then true; end

#----
case foo; in A(x:) then true; end

#----
case foo; in A() then true; end

#----
case foo; in A[1, 2] then true; end

#----
case foo; in A[x:] then true; end

#----
case foo; in A[] then true; end

#----
meth (-1.3).abs

#----
foo (-1.3).abs

#----
foo[m bar]

#----
m a + b do end

#----
+2.0 ** 10

#----
-2 ** 10

#----
-2.0 ** 10

#----
class << foo; nil; end

#----
def f (((a))); end

#----
def f ((a, a1)); end

#----
def f ((a, *r)); end

#----
def f ((a, *r, p)); end

#----
def f ((a, *)); end

#----
def f ((a, *, p)); end

#----
def f ((*r)); end

#----
def f ((*r, p)); end

#----
def f ((*)); end

#----
def f ((*, p)); end

#----
->{ }

#----
foo[bar,]

#----
->{ }

#----
-> * { }

#----
-> do end

#----
m ->(a = ->{_1}) {a}

#----
m ->(a: ->{_1}) {a}

#----
%i[foo bar]

#----
f (g rescue nil)

#----
[/()\1/, ?#]

#----
`foo#{bar}baz`

#----
"#{1}"

#----
%W"#{1}"

#----
def f foo:
; end

#----
def f foo: -1
; end

#----
foo, bar = m foo

#----
foo.a &&= 1

#----
foo[0, 1] &&= 2

#----
->(a) { }

#----
-> (a) { }

#----
fun(foo, :foo => 1)

#----
fun(foo, :foo => 1, &baz)

#----
foo[0, 1] += 2

#----
@@foo

#----
@foo, @@bar = *foo

#----
a, b = *foo, bar

#----
a, *b = bar

#----
a, *b, c = bar

#----
a, * = bar

#----
a, *, c = bar

#----
*b = bar

#----
*b, c = bar

#----
* = bar

#----
*, c, d = bar

#----
42i

#----
42ri

#----
42.1i

#----
42.1ri

#----
case; when foo; 'foo'; end

#----
f{ |a, b,| }

#----
p begin 1.times do 1 end end

#----
retry

#----
p <<~E
E

#----
p <<~E
  E

#----
p <<~E
  x
E

#----
p <<~E
  x
    y
E

#----
p <<~E
  x
    y
E

#----
p <<~E
  x
        y
E

#----
p <<~E
      x
        y
E

#----
p <<~E
          x
  y
E

#----
p <<~E
  x

y
E

#----
p <<~E
  x

  y
E

#----
p <<~E
    x
  \  y
E

#----
p <<~E
    x
  \  y
E

#----
p <<~"E"
    x
  #{foo}
E

#----
p <<~`E`
    x
  #{foo}
E

#----
p <<~"E"
    x
  #{"  y"}
E

#----
case foo; in 1..2 then true; end

#----
case foo; in 1.. then true; end

#----
case foo; in ..2 then true; end

#----
case foo; in 1...2 then true; end

#----
case foo; in 1... then true; end

#----
case foo; in ...2 then true; end

#----
begin; meth; rescue; foo; else; bar; end

#----
m [] do end

#----
m [], 1 do end

#----
%w[foo bar]

#----
return fun foo do end

#----
fun (1
)

#----
/foo#{bar}baz/

#----
if (a, b = foo); end

#----
foo.(1)

#----
foo::(1)

#----
1..

#----
1...

#----
def foo(...); bar(...); end

#----
/#{1}(?<match>bar)/ =~ 'bar'

#----
foo = meth rescue bar

#----
begin; meth; ensure; bar; end

#----
var = 10; var

#----
begin; meth; rescue; foo; end

#----
begin; meth; rescue => ex; bar; end

#----
begin; meth; rescue => @ex; bar; end

#----
case foo; in {} then true; end

#----
case foo; in a: 1 then true; end

#----
case foo; in { a: 1 } then true; end

#----
case foo; in { a: 1, } then true; end

#----
case foo; in a: then true; end

#----
case foo; in **a then true; end

#----
case foo; in ** then true; end

#----
case foo; in a: 1, b: 2 then true; end

#----
case foo; in a:, b: then true; end

#----
case foo; in a: 1, _a:, ** then true; end

#----
case foo;
        in {a: 1
        }
          false
      ; end

#----
case foo;
        in {a:
              2}
          false
      ; end

#----
case foo;
        in {Foo: 42
        }
          false
      ; end

#----
case foo;
        in a: {b:}, c:
          p c
      ; end

#----
case foo;
        in {a:
        }
          true
      ; end

#----
lambda{|;a|a}

#----
-> (arg={}) {}

#----
        case [__FILE__, __LINE__ + 1, __ENCODING__]
          in [__FILE__, __LINE__, __ENCODING__]
        end


#----
nil

#----
def f (foo: 1, bar: 2, **baz, &b); end

#----
def f (foo: 1, &b); end

#----
def f **baz, &b; end

#----
def f *, **; end

#----
false

#----
a ||= 1

#----
if foo then bar; else baz; end

#----
if foo; bar; else baz; end

#----
a b{c d}, "x" do end

#----
a b(c d), "x" do end

#----
a b{c(d)}, "x" do end

#----
a b(c(d)), "x" do end

#----
a b{c d}, /x/ do end

#----
a b(c d), /x/ do end

#----
a b{c(d)}, /x/ do end

#----
a b(c(d)), /x/ do end

#----
a b{c d}, /x/m do end

#----
a b(c d), /x/m do end

#----
a b{c(d)}, /x/m do end

#----
a b(c(d)), /x/m do end

#----
{ foo: 2, **bar }

#----
begin; meth; rescue; baz; ensure; bar; end

#----
a&.b

#----
super foo, bar do end

#----
super do end

#----
let () { m(a) do; end }

#----
"foo#@a" "bar"

#----
/#)/x

#----
'foobar'

#----
%q(foobar)

#----
not m foo

#----
class Foo < a:b; end

#----
?a

#----
foo ? 1 : 2

#----
def f(*); end

#----
case foo; in **nil then true; end

#----
foo.fun

#----
foo::fun

#----
foo::Fun()

#----
if foo then bar; end

#----
if foo; bar; end

#----
return(foo)

#----
return foo

#----
return()

#----
return

#----
undef foo, :bar, :"foo#{1}"

#----
f <<-TABLE do
TABLE
end

#----
case foo; when 'bar'; bar; else baz; end

#----
begin; rescue LoadError; else; end

#----
foo += m foo

#----
unless foo then bar; end

#----
unless foo; bar; end

#----
{ foo: 2 }

#----
fun (1) {}

#----
foo.fun (1) {}

#----
foo::fun (1) {}

#----
if (bar; a, b = foo); end

#----
meth do; foo; rescue; bar; end

#----
foo, bar = meth rescue [1, 2]

#----
 '#@1'

#----
 '#@@1'

#----
<<-'HERE'
#@1
HERE

#----
<<-'HERE'
#@@1
HERE

#----
 %q{#@1}

#----
 %q{#@@1}

#----
 "#@1"

#----
 "#@@1"

#----
<<-"HERE"
#@1
HERE

#----
<<-"HERE"
#@@1
HERE

#----
 %{#@1}

#----
 %{#@@1}

#----
 %Q{#@1}

#----
 %Q{#@@1}

#----
 %w[ #@1 ]

#----
 %w[ #@@1 ]

#----
 %W[#@1]

#----
 %W[#@@1]

#----
 %i[ #@1 ]

#----
 %i[ #@@1 ]

#----
 %I[#@1]

#----
 %I[#@@1]

#----
 :'#@1'

#----
 :'#@@1'

#----
 %s{#@1}

#----
 %s{#@@1}

#----
 :"#@1"

#----
 :"#@@1"

#----
 /#@1/

#----
 /#@@1/

#----
 %r{#@1}

#----
 %r{#@@1}

#----
 %x{#@1}

#----
 %x{#@@1}

#----
 `#@1`

#----
 `#@@1`

#----
<<-`HERE`
#@1
HERE

#----
<<-`HERE`
#@@1
HERE

#----
meth[] {}

#----
"#@a #@@a #$a"

#----
/source/im

#----
foo && (a, b = bar)

#----
foo || (a, b = bar)

#----
if foo; bar; elsif baz; 1; else 2; end

#----
def f(&block); end

#----
m "#{}#{()}"

#----


#----
a &&= 1

#----
::Foo

#----
class Foo; end

#----
class Foo end

#----
begin; meth; rescue Exception, foo; bar; end

#----
1..2

#----
case foo; in x then x; end

#----
case 1; in 2; 3; else; end

#----
-> a: 1 { }

#----
-> a: { }

#----
def foo; end

#----
def String; end

#----
def String=; end

#----
def until; end

#----
def BEGIN; end

#----
def END; end

#----
foo.fun bar

#----
foo::fun bar

#----
foo::Fun bar

#----
@@var = 10

#----
a = b = raise :x

#----
a += b = raise :x

#----
a = b += raise :x

#----
a += b += raise :x

#----
p ->() do a() do end end

#----
foo.a ||= 1

#----
foo[0, 1] ||= 2

#----
p -> { :hello }, a: 1 do end

#----
foo[0, 1] += m foo

#----
{ 'foo': 2 }

#----
{ 'foo': 2, 'bar': {}}

#----
f(a ? "a":1)

#----
while foo do meth end

#----
while foo; meth end

#----
foo = bar, 1

#----
foo = *bar

#----
foo = baz, *bar

#----
m = -> *args do end

#----
defined? foo

#----
defined?(foo)

#----
defined? @foo

#----
A += 1

#----
::A += 1

#----
B::A += 1

#----
def x; self::A ||= 1; end

#----
def x; ::A ||= 1; end

#----
foo.a += 1

#----
foo::a += 1

#----
foo.A += 1

#----
p <<~"E"
  x\n   y
E

#----
case foo; in (1) then true; end

#----
$foo

#----
case; when foo; 'foo'; else 'bar'; end

#----
a @b do |c|;end

#----
p :foo, {a: proc do end, b: proc do end}

#----
p :foo, {:a => proc do end, b: proc do end}

#----
p :foo, {"a": proc do end, b: proc do end}

#----
p :foo, {proc do end => proc do end, b: proc do end}

#----
p :foo, {** proc do end, b: proc do end}

#----
<<~E
    1 \
    2
    3
E


#----
<<-E
    1 \
    2
    3
E


#----
def f(**nil); end

#----
m { |**nil| }

#----
->(**nil) {}

#----
a #
#
.foo


#----
a #
  #
.foo


#----
a #
#
&.foo


#----
a #
  #
&.foo


#----
::Foo = 10

#----
not foo

#----
not(foo)

#----
not()

#----
:"foo#{bar}baz"

#----
@var = 10

#----
"foo#{bar}baz"

#----
case foo; in 1 => a then true; end

#----
def f(foo: 1); end

#----
a ? b & '': nil

#----
meth 1 do end.fun bar

#----
meth 1 do end.fun(bar)

#----
meth 1 do end::fun bar

#----
meth 1 do end::fun(bar)

#----
meth 1 do end.fun bar do end

#----
meth 1 do end.fun(bar) {}

#----
meth 1 do end.fun {}

#----
def f(**); end

#----
foo and bar

#----
foo && bar

#----
!(a, b = foo)

#----
def m; class << self; class C; end; end; end

#----
def m; class << self; module M; end; end; end

#----
def m; class << self; A = nil; end; end

#----
begin foo!; bar! end

#----
foo = m foo

#----
foo = bar = m foo

#----
def f(**foo); end

#----
%I[foo #{bar}]

#----
%I[foo#{bar}]

#----
self

#----
a = 1; a b: 1

#----
def foo raise; raise A::B, ''; end

#----
/(?<match>bar)/ =~ 'bar'; match

#----
let (:a) { m do; end }

#----
fun

#----
fun!

#----
fun(1)

#----
fun () {}

#----
if /wat/; end

#----
!/wat/

#----
# coding:utf-8
         "\xD0\xBF\xD1\x80\xD0\xBE\xD0\xB2\xD0\xB5\xD1\x80\xD0\xBA\xD0\xB0"

#----
while def foo; tap do end; end; break; end

#----
while def self.foo; tap do end; end; break; end

#----
while def foo a = tap do end; end; break; end

#----
while def self.foo a = tap do end; end; break; end
