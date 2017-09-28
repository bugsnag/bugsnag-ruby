require 'resque'
require 'bugsnag'

Bugsnag.configure do |config|
  config.api_key = 'f35a2472bd230ac0ab0f52715bbdc65d'
end

# Unhandled Exception example
class Crash
  @queue = :crash

  def self.perform
    raise Exception.new "Crashed - Check your Bugsnag dashboard"
  end
end

# Unhandled with callback Exception example
class Callback
  @queue = :callback

  def self.perform
    Bugsnag.before_notify_callbacks << proc { |report|
      new_tab = {
        message: 'Rack demo says: Everything is great',
        code: 200
      }
      report.add_tab(:diagnostics, new_tab)
    }
    raise Exception.new "Crashed - Check the Bugsnag dashboard for diagnostic data"
  end
end

# Handled example
class Notify
  @queue = :notify

  def self.perform
    Bugsnag.notify(Exception.new "Didn't crash, but sent a notification anyway")
    puts "The Resque worker hasn't crashed, but it has sent a notification, so go check out the dashboard!"
  end
end

# Handled example with additional data
class Data
  @queue = :data

  def self.perform
    error = Exception.new "Didn't crash, but sent a notification anyway"
    Bugsnag.notify error do |report|
      report.add_tab(:queue, {
        :name => "data",
        :fatal => false
      })
      report.add_tab(:diagnostics, {
        :message => 'Rack demo says: Everything is great',
      })
    end
    puts "The Resque worker hasn't crashed, but it has sent a notification, with additional data to the dashboard"
  end
end

# Handled example with set severity
class Severity
  @queue = :severity

  def self.perform
    error = Exception.new "Didn't crash, but sent a notification anyway"
    Bugsnag.notify error do |report|
      report.severity = "info"
    end
    puts "The Resque worker hasn't crashed but check the severity of the dashboard notification"
  end
end

Resque.enqueue(Crash)
Resque.enqueue(Callback)
Resque.enqueue(Notify)
Resque.enqueue(Data)
Resque.enqueue(Severity)
