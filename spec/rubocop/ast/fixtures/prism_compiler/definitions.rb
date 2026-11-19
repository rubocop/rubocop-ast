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
