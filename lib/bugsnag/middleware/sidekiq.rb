module Bugsnag::Middleware
  class Sidekiq
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(notification)
      notification.add_tab(:sidekiq, notification.request_data[:sidekiq_msg])
      notification.context ||= "sidekiq##{notification.request_data[:sidekiq_queue]}"
      @bugsnag.call(notification)
    end
  end
end
