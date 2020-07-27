module SidekiqWorkers
  class CrashWorker
    include Sidekiq::Worker
    sidekiq_options :retry => false

    def perform
      raise Exception.new "Sidekiq crashed - Check your Bugsnag dashboard"
    end
  end

  class MetadataWorker
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
end
