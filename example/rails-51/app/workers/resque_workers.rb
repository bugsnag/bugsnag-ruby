module ResqueWorkers
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
          message: 'Resque demo says: Everything is great',
          code: 200
        }
        report.add_tab(:diagnostics, new_tab)
      }
      raise Exception.new "Crashed - Check the Bugsnag dashboard for diagnostic data"
    end
  end

  # Handled example with additional data
  class Metadata
    @queue = :metadata

    def self.perform
      error = Exception.new "Didn't crash, but sent a notification anyway"
      Bugsnag.notify error do |report|
        report.add_tab(:queue, {
          :name => "metadata",
          :fatal => false
        })
        report.add_tab(:diagnostics, {
          :message => 'Resque demo says: Everything is great',
        })
      end
      puts "The Resque worker hasn't crashed, but it has sent a notification, with additional data to the dashboard"
    end
  end
end