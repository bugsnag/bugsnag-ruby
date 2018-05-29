require 'bundler'
Bundler.require

class BugsnagWorker
  @queue = :compute

  def self.perform(operation, a, b)
    puts "Work started for #{operation} on #{a} and #{b}"
    sleep 5
    puts "#{a} #{operation} #{b} = #{a.send(operation, b)}"
  end
end
