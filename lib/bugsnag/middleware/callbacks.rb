module Bugsnag::Middleware
  class Callbacks

    ##
    # Calls all callbacks pre-registered in the configuration.
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    ##
    # Executes the callback.
    def call(report)
      if report.request_data[:before_callbacks]
        report.request_data[:before_callbacks].each {|c| c.call(*[report][0...c.arity]) }
      end

      @bugsnag.call(report)
    end
  end
end
