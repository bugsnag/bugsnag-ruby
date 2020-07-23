def foo
  bar
end

def bar
  baz
end

def baz
  xyz
end

def xyz
  raise 'uh oh'
end

def abc
  puts 'abc'
end

def abcdef
  puts 'abcdef'
end

def abcdefghi
  puts 'abcdefghi'
end

foo
