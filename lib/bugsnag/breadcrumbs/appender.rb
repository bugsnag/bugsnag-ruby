require_relative "logger"
require "logging"

module Bugsnag::Breadcrumbs
  class Appender < Logging::Appender
    def initialize(level = Logger::INFO)
      super "Bugsnag", { :level => level }
    end

    def <<(message)
      return if closed?
      Bugsnag::Breadcrumbs::Logger.log_breadcrumb(message)
    end

    def append(event)
      return if closed? || !allow(event)

      message = event.data.to_s
      metadata = {
        :method => event.method.to_s,
        :file => event.file.to_s,
        :line => event.line.to_s
      }.delete_if {|k,v| v == ""}

      severity = Bugsnag::Breadcrumbs::Logger.get_severity_name(event.level)
      Bugsnag::Breadcrumbs::Logger.log_breadcrumb(message, metadata, severity)
    end
  end
end
