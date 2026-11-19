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
