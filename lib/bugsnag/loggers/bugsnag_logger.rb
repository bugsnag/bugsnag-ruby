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
      @open = true
    end

    def add(severity, message = nil, progname = nil, &block)
      if supports_level?(severity) && @open
        Bugsnag.leave_breadcrumb(message, Bugsnag::Breadcrumbs::LOG_TYPE, {
          :progname => progname,
          :severity => severity
        })
      end
    end
    alias :log :add

    def <<(message)
      add "unknown", message
    end

    def level(severity)
      if Bugsnag::Loggers::LEVELS.include? severity
        @level = severity
      end
    end
    alias :sev_threshold :level

    def info(message)
      add "info", message
    end

    def info(progname = nil, &block)
      yield message="" if block_given?
      add "info", message, progname
    end

    def info?
      supports_level?("info")
    end

    def debug(progname = nil, &block)
      yield message="" if block_given?
      add "debug", message, progname
    end

    def debug?
      supports_level?("debug")
    end

    def error(progname = nil, &block)
      yield message="" if block_given?
      add "error", message, progname
    end

    def error
      supports_level?("error")
    end

    def fatal(progname = nil, &block)
      yield message="" if block_given?
      add "fatal", message, progname
    end

    def fatal?
      supports_level?("fatal")
    end

    def warn(progname = nil, &block)
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
      @open = false
      true
    end

    def reopen
      @open = true
      true
    end

    private
    def supports_level?(level)
      if level == "unknown"
        true
      else 
        Bugsnag::Loggers::LEVELS.index(level) >= Bugsnag::Loggers::LEVELS.index(@level)
      end
    end

  end
end