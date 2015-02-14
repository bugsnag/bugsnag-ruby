module Bugsnag::Middleware
  class Sidekiq
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(notification)
      sidekiq = notification.request_data[:sidekiq]
      notification.add_tab(:sidekiq, sidekiq) if sidekiq
      @bugsnag.call(notification)
    end
  end
end
