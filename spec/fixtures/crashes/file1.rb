require_relative 'file2'

module File1
  def self.foo1
    File2.foo2
  end

  def self.bar1
    File2.bar2
  end

  def self.baz1
    File2.baz2
  end

  def self.abc1
    puts 'abc'
  end

  def self.abcdef1
    puts 'abcdef1'
  end

  def self.abcdefghi1
    puts 'abcdefghi1'
  end
end

File1.foo1
