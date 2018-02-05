module Bugsnag::Middleware
  class Sidekiq

    ##
    # Extracts and attaches sidekiq data to the request.
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    ##
    # Executes the callback.
    def call(report)
      sidekiq = report.request_data[:sidekiq]
      if sidekiq
        report.add_tab(:sidekiq, sidekiq)
        report.context ||= "#{sidekiq[:msg]['wrapped'] || sidekiq[:msg]['class']}@#{sidekiq[:msg]['queue']}"
      end
      @bugsnag.call(report)
    end
  end
end
