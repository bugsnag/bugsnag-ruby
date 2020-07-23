module File2
  def self.foo2
    File1.bar1
  end

  def self.bar2
    File1.baz1
  end

  def self.baz2
    raise 'uh oh'
  end

  def self.abc2
    puts 'abc'
  end

  def self.abcdef2
    puts 'abcdef2'
  end

  def self.abcdefghi2
    puts 'abcdefghi2'
  end
end
