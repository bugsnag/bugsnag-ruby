module Bugsnag
  class Sidekiq
    def call(worker, msg, queue)
      begin
        yield
      rescue => ex
        Bugsnag.notify(ex, :meta_data => {:sidekiq => msg })
        raise
      end
    end
  end
end

::Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add ::Bugsnag::Sidekiq
  end
end