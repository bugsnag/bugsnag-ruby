class TestModel < ApplicationRecord
  def self.print
    puts "yo"
  end

  def self.fail
    raise "uh oh"
  end

  def self.fail_with_args(a)
    raise "uh oh"
  end
end
