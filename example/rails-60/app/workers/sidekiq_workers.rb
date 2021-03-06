module SidekiqWorkers
  class CrashWorker
    include Sidekiq::Worker
    sidekiq_options :retry => false

    def perform
      raise 'Sidekiq crashed - Check your Bugsnag dashboard'
    end
  end

  class MetadataWorker
    include Sidekiq::Worker
    sidekiq_options :retry => false

    def perform
      error = Exception.new('Sidekiq notified with metadata - Check your Bugsnag dashboard')

      Bugsnag.notify(error) do |report|
        report.add_tab(:function, {
          name: 'Metadata',
          fatal: false
        })

        report.add_tab(:diagnostics, {
          message: 'Sidekiq demo says: Everything is great',
        })
      end
    end
  end
end
