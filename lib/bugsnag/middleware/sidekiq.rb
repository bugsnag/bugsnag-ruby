module Bugsnag::Middleware
  class Sidekiq
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(notification)
      sidekiq = notification.request_data[:sidekiq]
      if sidekiq
        notification.add_tab(:sidekiq, sidekiq)
        notification.context ||= "#{sidekiq[:msg]['wrapper'] || sidekiq[:msg]['class']}##{sidekiq[:msg]['queue']}"
      end
      @bugsnag.call(notification)
    end
  end
end
