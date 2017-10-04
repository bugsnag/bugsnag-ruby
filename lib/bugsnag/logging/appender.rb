require_relative "logger"
require "logging"

module Bugsnag::Logging
  class Appender < Logging::Appender
    def initialize(level=Logger::INFO)
      super "Bugsnag", {:level => level}
    end

    def <<(message)
      return if closed?
      Bugsnag::Logging.log_breadcrumb(message)
    end

    def append(event)
      return if (closed?)||(!allow(event))
      if (event.method.size > 0) && (event.file.size > 0) && (event.line.size > 0)
        metadata = {
          :trace => {
            :method => event.method,
            :file => event.file,
            :line => event.line
          },
          :data => event.data
        }
      else
        metadata = event.data
      end      
      severity = Bugsnag::Logging.get_severity_name(event.level)
      Bugsnag::Logging.log_breadcrumb(event.logger, metadata, severity)
    end
  end
end
