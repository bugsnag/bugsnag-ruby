class SidekiqCallbackWorker
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
    raise Exception.new "Sidekiq crashed, but the callback added metadata - Check your Bugsnag dashboard"
  end
end

class SidekiqCrashWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    raise Exception.new "Sidekiq crashed - Check your Bugsnag dashboard"
  end
end

class SidekiqMetadataWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    Bugsnag.notify(Exception.new "Sidekiq notified with metadata - Check your Bugsnag dashboard") do |report|
      report.add_tab(:function, {
        :name => "Metadata",
        :fatal => false
      })
      report.add_tab(:diagnostics, {
        :message => 'Sidekiq demo says: Everything is great',
      })
    end
  end
end
