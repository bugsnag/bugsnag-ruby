module Bugsnag::Middleware
  ##
  # Attaches Sinatra information to an error report
  class Sinatra
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(report)
      report.add_tab(:app, :sinatraVersion => ::Sinatra::VERSION)
      @bugsnag.call(report)
    end
  end
end
