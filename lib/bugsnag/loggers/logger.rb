require "logger"
require "bugsnag"

module Bugsnag::Loggers

  SEVERITIES = [
    "debug",
    "info",
    "warn",
    "error",
    "fatal",
    "unknown"
  ]

  class Logger < Logger

    def initialize(level=Logger::INFO)
      @open = true
      super nil, level
    end

    def add(severity, message = nil, progname = nil)
      return unless @open
      if block_given?
        message = yield message
      elsif message.nil?
        message = progname
      end
      if severity >= level
        severity_name =  get_severity_name(severity)
        log_breadcrumb(message, progname, severity_name)
      end
    end
    alias :log :add

    def <<(message)
      return unless @open
      log_breadcrumb(message)
    end

    def close
      @open = false
      true
    end

    def reopen
      @open = true
      true
    end

    private
    def log_breadcrumb(message, progname = nil, severity = "unknown")
      Bugsnag.leave_breadcrumb(message, Bugsnag::Breadcrumbs::LOG_TYPE, {
        :progname => progname,
        :severity => severity
      })
    end

    private
    def get_severity_name(severity)
      if (0..5).include? severity
        Bugsnag::Loggers::SEVERITIES[severity]
      else
        severity
      end
    end
  end
end