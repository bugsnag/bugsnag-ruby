require 'bugsnag'
require 'pp'

def configure_basics
  Bugsnag.configure do |conf|
    pp "Configuring `api_key` to #{ENV['MAZE_API_KEY']}"
    conf.api_key = ENV['MAZE_API_KEY']
    pp "Configuring `endpoint` to #{ENV['MAZE_ENDPOINT']}"
    conf.endpoint = ENV['MAZE_ENDPOINT']
  end
end

def add_at_exit
  at_exit do
    if $!
      Bugsnag.notify($!, true)
    end
  end
end