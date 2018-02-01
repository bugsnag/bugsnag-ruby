require 'bundler'
Bundler.require

Sidekiq.configure_client do |config|
  config.redis = { :url => 'redis://redis:6379', :size => 1 }
end

Sidekiq.configure_server do |config|
  config.redis = { :url => 'redis://redis:6379' }
end

class PlainOldRuby
  include Sidekiq::Worker

  def perform(how_hard="super hard", how_long=1)
    sleep how_long
    puts "Workin' #{how_hard}"
  end
end
