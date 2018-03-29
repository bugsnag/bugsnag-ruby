require "logger"
require "bugsnag"

module Bugsnag::Logging
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

  def self.log_breadcrumb(name, data = nil, severity = "unknown")
    metadata = {
      :severity => severity
    }
    if data.is_a? Hash
      metadata.merge!(data)
    elsif !data.nil?
      metadata[:data] = data
    end

    Bugsnag.leave_breadcrumb(name, Bugsnag::Breadcrumbs::LOG_TYPE, metadata)
  end

  class Logger < Logger
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

      Bugsnag::Logging.log_breadcrumb(message, { :progname => progname }, Bugsnag::Logging.get_severity_name(severity)) if severity >= level
    end
    alias log add

    def <<(message)
      return unless @open
      Bugsnag::Logging.log_breadcrumb(message)
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
