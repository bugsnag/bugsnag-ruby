module Bugsnag::Loggers
  class MultiLogger

    def initialize(loggers = [])
      @loggers = loggers
    end

    def call_loggers(method, *args)
      @loggers.each do |logger|
        logger.send(method, *args)
      end
    end

    def <<(*args)
      call_loggers(:<<, *args)
    end

    def add(*args)
      call_loggers(:add, *args)
    end
    alias :log :add

    def debug(*args)
      call_loggers(:debug, *args)
    end

    def info(*args)
      call_loggers(:info, *args)
    end

    def warn(*args)
      call_loggers(:warn, *args)
    end

    def error(*args)
      call_loggers(:error, *args)
    end

    def fatal(*args)
      call_loggers(:fatal, *args)
    end

    def unknown(*args)
      call_loggers(:unknown, *args)
    end

    def close
      call_loggers(:close)
    end

    def debug?
      supports_level?(:debug?)
    end

    def info?
      supports_level?(:info?)
    end

    def warn?
      supports_level?(:warn?)
    end
    
    def error?
      supports_level?(:error?)
    end

    def fatal?
      supports_level?(:fatal?)
    end

    private
    def supports_level?(level)
      @loggers.any {|logger| logger.send(level)}
    end
  end
end