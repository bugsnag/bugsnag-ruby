require "resque"
require "resque/failure/multiple"

module Bugsnag
  class Resque < ::Resque::Failure::Base
    def self.configure(&block)
      add_failure_backend
      Bugsnag.configure(&block)
    end

    def self.add_failure_backend
      return if ::Resque::Failure.backend == self

      # Ensure resque is using a "Multiple" failure backend
      unless ::Resque::Failure.backend < ::Resque::Failure::Multiple
        original_backend = ::Resque::Failure.backend
        ::Resque::Failure.backend = ::Resque::Failure::Multiple
        ::Resque::Failure.backend.classes ||= []
        ::Resque::Failure.backend.classes << original_backend
      end

      # Add Bugsnag failure backend
      unless ::Resque::Failure.backend.classes.include?(self)
        ::Resque::Failure.backend.classes << self
      end
    end

    def save
      Bugsnag.notify(exception, true) do |report|
        report.severity = "error"
        report.set_handled_state({
          :type => "middleware_handler",
          :attributes => {
            :name => "mailman"
          }
        })
        report.meta_data.merge!({:context => "#{payload['class']}@#{queue}", :payload => payload, :delivery_method => :synchronous})
      end
    end
  end
end

# For backwards compatibility
Resque::Failure::Bugsnag = Bugsnag::Resque

# Auto-load the failure backend
Bugsnag::Resque.add_failure_backend

Resque.before_first_fork do
  Bugsnag.configuration.app_type = "resque"
  Bugsnag.configuration.delivery_method = :synchronous
end
