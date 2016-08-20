module Bugsnag::Middleware
  class Callbacks
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(report)
      if report.request_data[:before_callbacks]
        report.request_data[:before_callbacks].each {|c| c.call(*[report][0...c.arity]) }
      end

      @bugsnag.call(report)
    end
  end
end
