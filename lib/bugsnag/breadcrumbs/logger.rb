require "logger"
require "bugsnag"

module Bugsnag::Breadcrumbs
  class Logger < Logger
    SEVERITIES = [
      "debug",
      "info",
      "warn",
      "error",
      "fatal",
      "unknown"
    ]

    def self.get_severity_name(severity)
      if (0..5).cover? severity
        SEVERITIES[severity]
      else
        severity
      end
    end

    def self.log_breadcrumb(message, data = nil, severity = "unknown")
      metadata = {
        :severity => severity,
        :message => message
      }
      if data.is_a? Hash
        metadata.merge!(data)
      elsif !data.nil?
        metadata[:data] = data.to_s
      end

      Bugsnag.leave_breadcrumb("Log output", metadata, Bugsnag::Breadcrumbs::LOG_TYPE)
    end

    def initialize(level = Logger::INFO)
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
        Bugsnag::Breadcrumbs::Logger.log_breadcrumb(
          message,
          { :progname => progname },
          Bugsnag::Breadcrumbs::Logger.get_severity_name(severity))
      end
    end
    alias log add

    def <<(message)
      return unless @open
      Bugsnag::Breadcrumbs::Logger.log_breadcrumb(message)
    end

    def close
      @open = false
      true
    end

    def reopen
      @open = true
      true
    end
  end
end
