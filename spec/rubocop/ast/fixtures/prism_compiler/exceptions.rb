begin; a; rescue; b; end
begin; a; rescue B, C => d then e; rescue F; g; else h; ensure i; end
begin; a; rescue; retry; end
begin; ensure; end
def a; b; rescue => @c; d; ensure; e; end
foo do a rescue b end
foo do a; rescue; b; ensure; c; end
a rescue b
a = b rescue c
