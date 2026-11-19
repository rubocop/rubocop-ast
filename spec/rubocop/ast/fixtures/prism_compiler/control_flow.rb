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
