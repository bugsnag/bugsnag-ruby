require 'bundler'
Bundler.require

Bugsnag.configure do |conf|
  puts "Configuring `api_key` to #{ENV['BUGSNAG_API_KEY']}"
  conf.api_key = ENV['BUGSNAG_API_KEY']
  puts "Configuring `endpoint` to #{ENV['BUGSNAG_ENDPOINT']}"
  conf.endpoint = ENV['BUGSNAG_ENDPOINT']

  if ENV.include?('BUGSNAG_DELIVERY_METHOD')
    puts "Configuring `delivery_method` to #{ENV['BUGSNAG_DELIVERY_METHOD']}"
    conf.delivery_method = ENV['BUGSNAG_DELIVERY_METHOD'].to_sym
  end

  conf.add_on_error(proc do |report|
    report.add_tab(:config, {
      delivery_method: conf.delivery_method.to_s
    })
  end)
end

Sidekiq.configure_client do |config|
  config.redis = { :url => 'redis://redis:6379', :size => 1 }
end

Sidekiq.configure_server do |config|
  config.redis = { :url => 'redis://redis:6379' }
end

class HandledError
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    Bugsnag.notify(RuntimeError.new("Handled"))
  end
end

class UnhandledError
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    raise RuntimeError.new("Unhandled")
  end
end
