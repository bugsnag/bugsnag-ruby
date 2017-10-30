require 'sidekiq'
require 'bugsnag'

Bugsnag.configure do |config|
  config.api_key = 'YOUR_API_KEY'
end

# If your client is single-threaded, we just need a single connection in our Redis connection pool
Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'x', :size => 1 }
end

# Sidekiq server is multi-threaded so our Redis connection pool size defaults to concurrency (-c)
Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'x' }
end

# Unhandled example
class Crash
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    raise Exception.new "Crashed - Check your Bugsnag dashboard"
  end
end

# Unhandled example with callback
class Callback
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    Bugsnag.before_notify_callbacks << proc { |report|
      new_tab = {
        message: 'Sidekiq demo says: Everything is great',
        code: 200
      }
      report.add_tab(:diagnostics, new_tab)
    }
    raise Exception.new "Crashed - Check the Bugsnag dashboard for diagnostic data"
  end
end

# Handled example
class Notify
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    Bugsnag.notify(Exception.new "Didn't crash, but sent a notification anyway")
    puts "The Sidekiq worker hasn't crashed, but it has sent a notification, so go check out the dashboard!"
  end
end

# Handled example with additional data
class Metadata
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    error = Exception.new "Didn't crash, but sent a notification anyway"
    Bugsnag.notify error do |report|
      report.add_tab(:function, {
        :name => "Metadata",
        :fatal => false
      })
      report.add_tab(:diagnostics, {
        :message => 'Sidekiq demo says: Everything is great',
      })
    end
    puts "The Sidekiq worker hasn't crashed, but it has sent a notification, with additional data to the dashboard"
  end
end


# Handled example with set severity
class Severity
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    error = Exception.new "Didn't crash, but sent a notification anyway"
    Bugsnag.notify error do |report|
      report.severity = "info"
    end
    puts "The Sidekiq worker hasn't crashed but check the severity of the dashboard notification"
  end
end