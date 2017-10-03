require "logger"
require "bugsnag"
require "bugsnag/loggers/log_device"

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
      @log_device = Bugsnag::Loggers::LogDevice.new
      super @log_device, level
    end

    def add(severity, message = nil, progname = nil)
      return unless @open
      if block_given?
        message = yield message
      elsif message.nil?
        message = progname
      end
      if severity >= level
        @log_device.write(message, progname, Bugsnag::Loggers::SEVERITIES[severity])
      end
    end
    alias :log :add

    def <<(message)
      return unless @open
      @log_device.write message
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