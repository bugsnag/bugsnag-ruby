module Bugsnag::Middleware
  class SessionData
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(report)
      session = Thread.current[Bugsnag::Report::THREAD_SESSION]
      unless session.nil?
        if report.unhandled
          session['events']['unhandled'] += 1
        else
          session['events']['unhandled'] += 1
        end
        report.session = session
      end

      @bugsnag.call(report)
    end
  end
end
