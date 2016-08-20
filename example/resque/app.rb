require 'resque'
require 'bugsnag'

Bugsnag.configure do |config|
  config.api_key = '066f5ad3590596f9aa8d601ea89af845'
end

# This is a simple Resque job.
class Archive
  @queue = :test

  def self.perform(how_hard="super hard", how_long=1)
    puts "Workin' #{how_hard} #{how_long}"
    raise 'Uh oh!'
  end
end

Resque.enqueue(Archive, "super hard", 1)

# To run a worker run
#QUEUE=* rake resque:work
