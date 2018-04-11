require_relative "logger"
require "logging"

module Bugsnag::Breadcrumbs
  class Appender < Logging::Appender
    def initialize(level = Logger::INFO)
      super "Bugsnag", { :level => level }
    end

    def <<(message)
      return if closed?
      Bugsnag::Breadcrumbs.log_breadcrumb(message)
    end

    def append(event)
      return if closed? || !allow(event)

      metadata = if !event.method.empty? && !event.file.empty? && !event.line.empty?
                   {
                     :trace => {
                       :method => event.method,
                       :file => event.file,
                       :line => event.line
                     },
                     :data => event.data
                   }
                 else
                   event.data
                 end

      severity = Bugsnag::Breadcrumbs.get_severity_name(event.level)
      Bugsnag::Breadcrumbs.log_breadcrumb(event.logger, metadata, severity)
    end
  end
end
