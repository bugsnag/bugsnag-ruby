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

    def add(severity, message = nil, progname = nil)
      if supports_level?(severity) && @open
        breadcrumb(severity, message, progname)
      end
    end
    alias :log :add

    def <<(message)
      breadcrumb "unknown", message, nil
    end

    def level=(severity)
      if Bugsnag::Loggers::LEVELS.include? severity
        @level = severity
      end
    end
    alias :sev_threshold= :level=

    def info(message)
      add "info", message
    end

    def info(progname = nil, &block)
      yield_before_add "info", progname, &block
    end

    def info?
      supports_level?("info")
    end

    def debug(progname = nil, &block)
      yield_before_add "debug", progname, &block
    end

    def debug?
      supports_level?("debug")
    end

    def error(progname = nil, &block)
      yield_before_add "error", progname, &block
    end

    def error?
      supports_level?("error")
    end

    def fatal(progname = nil, &block)
      yield_before_add "fatal", progname, &block
    end

    def fatal?
      supports_level?("fatal")
    end

    def warn(progname = nil, &block)
      yield_before_add "warn", progname, &block
    end

    def warn?
      supports_level?("warn")
    end

    def unknown(progname = nil, &block)
      yield_before_add "unknown", progname, &block
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
    def yield_before_add(level, progname, &block)
      return false unless @open && supports_level?(level)
      message = yield if block_given?
      breadcrumb(level, message, progname)
    end

    private
    def supports_level?(level)
      if level == "unknown"
        true
      else 
        Bugsnag::Loggers::LEVELS.index(level) >= Bugsnag::Loggers::LEVELS.index(@level)
      end
    end

    private
    def breadcrumb(severity, message, progname)
      Bugsnag.leave_breadcrumb(message, Bugsnag::Breadcrumbs::LOG_TYPE, {
        :progname => progname,
        :severity => severity
      })
    end

  end
end