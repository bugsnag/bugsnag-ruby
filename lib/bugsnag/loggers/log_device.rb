require "bugsnag"
require "bugsnag/breadcrumbs/breadcrumb"

module Bugsnag::Loggers

  class LogDevice
    def initialize
      @open = true
    end

    def reopen
      @open = true
    end

    def close
      @open = false
    end

    def write(message, progname = nil, severity = "unknown")
      if @open
        Bugsnag.leave_breadcrumb(message, Bugsnag::Breadcrumbs::LOG_TYPE, {
          :progname => progname,
          :severity => severity
        })
      end
    end
  end
end