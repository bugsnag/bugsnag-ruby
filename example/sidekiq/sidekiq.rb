require 'sidekiq'
require 'bugsnag'

Bugsnag.configure do |config|
  config.api_key = '066f5ad3590596f9aa8d601ea89af845'
end

# If your client is single-threaded, we just need a single connection in our Redis connection pool
Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'x', :size => 1 }
end

# Sidekiq server is multi-threaded so our Redis connection pool size defaults to concurrency (-c)
Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'x' }
end

# Start up sidekiq via
# bundle exec sidekiq -r ./sidekiq.rb
# and then you can open up an IRB session like so:
# irb -r ./sidekiq.rb
# where you can then say
# PlainOldRuby.perform_async "like a dog", 3
#
class PlainOldRuby
  include Sidekiq::Worker

  def perform(how_hard="super hard", how_long=1)
    puts "Workin' #{how_hard} #{how_long}"
    raise 'Uh oh!'
  end
end
