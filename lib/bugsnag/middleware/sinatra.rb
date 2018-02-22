module Bugsnag::Middleware
  ##
  # Attaches Sinatra information to an error report
  class Sinatra
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(report)
      report.app_framework_versions[:sinatraVersion] = ::Sinatra::VERSION
      @bugsnag.call(report)
    end
  end
end
