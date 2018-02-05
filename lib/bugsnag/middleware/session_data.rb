module Bugsnag::Middleware
  class SessionData

    ##
    # Attaches the current session data to the report if necessary.
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    ##
    # Executes the callback.
    def call(report)
      session = Bugsnag::SessionTracker.get_current_session
      unless session.nil?
        if report.unhandled
          session[:events][:unhandled] += 1
        else
          session[:events][:handled] += 1
        end
        report.session = session
      end

      @bugsnag.call(report)
    end
  end
end
