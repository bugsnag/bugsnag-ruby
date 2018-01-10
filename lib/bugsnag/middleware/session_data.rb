module Bugsnag::Middleware
  class SessionData
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(report)
      session = Bugsnag::SessionTracker.get_current_session
      unless session.nil?
        if report.unhandled
          session[:events][:unhandled] += 1
        else
          session[:events][:handled] += 1
        end
        Bugsnag::SessionTracker.set_current_session session
        report.session = session
      end

      @bugsnag.call(report)
    end
  end
end
