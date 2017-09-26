require "bugsnag"
require "bugsnag/breadcrumbs/breadcrumb"

module Bugsnag::Loggers

  LEVELS = [
    "debug",
    "info",
    "warn",
    "error",
    "fatal"
  ]

  class BugsnagLogger

    attr_reader :level

    def initialize(level="info")
      @level = level
    end

    def add(severity, message = nil, progname = nil)
      if supports_level?(severity)
        Bugsnag.leave_breadcrumb(message, Bugsnag::Breadcrumbs::LOG_TYPE, {
          :progname => progname,
          :severity => severity
        })
      end
    end

    def <<(message)
      add "unknown", message
    end

    alias :sev_threshold :level
    def level(severity)
      if Loggers::LEVELS.include? severity
        @level = severity
      end
    end

    def info(message)
      add "info", message
    end

    def info(progname=nil, &block)
      yield message="" if block_given?
      add "info", message, progname
    end

    def info?
      supports_level?("info")
    end

    def debug(progname=nil, &block)
      yield message="" if block_given?
      add "debug", message, progname
    end

    def debug?
      supports_level?("debug")
    end

    def error(progname=nil, &block)
      yield message="" if block_given?
      add "error", message, progname
    end

    def error
      supports_level?("error")
    end

    def fatal(progname=nil, &block)
      yield message="" if block_given?
      add "fatal", message, progname
    end

    def fatal?
      supports_level?("fatal")
    end

    def warn(progname=nil, &block)
      yield message="" if block_given?
      add "warn", message, progname
    end

    def warn?
      supports_level?("warn")
    end

    def unknown(progname = nil, &block)
      yield message="" if block_given?
      add "unknown", message, progname
    end

    def close
      true
    end

    private
    def supports_level?(level)
      if level == "unknown"
        true
      else 
        Loggers::LEVELS.index(level) >= Loggers::LEVELS.index(@level)
      end
    end

  end
end