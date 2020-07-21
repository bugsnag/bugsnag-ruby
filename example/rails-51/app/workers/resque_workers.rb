module ResqueWorkers
  class Crash
    @queue = :crash

    def self.perform
      raise Exception.new "Crashed - Check your Bugsnag dashboard"
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
