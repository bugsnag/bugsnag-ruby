require "resque"
require "resque/failure/multiple"

module Bugsnag
  class Resque < ::Resque::Failure::Base

    FRAMEWORK_ATTRIBUTES = {
      :framework => "Resque"
    }

    ##
    # Callthrough to Bugsnag configuration.
    def self.configure(&block)
      add_failure_backend
      Bugsnag.configure(&block)
    end

    ##
    # Sets up the Resque failure backend.
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

    ##
    # Notifies Bugsnag of a raised exception.
    def save
      Bugsnag.notify(exception, true) do |report|
        report.severity = "error"
        report.severity_reason = {
          :type => Bugsnag::Report::UNHANDLED_EXCEPTION_MIDDLEWARE,
          :attributes => FRAMEWORK_ATTRIBUTES
        }

        context = "#{payload['class']}@#{queue}"
        report.meta_data.merge!({:context => context, :payload => payload})
        report.context = context
      end
    end
  end
end

# For backwards compatibility
Resque::Failure::Bugsnag = Bugsnag::Resque

# Auto-load the failure backend
Bugsnag::Resque.add_failure_backend

if Resque::Worker.new(:bugsnag_fork_check).fork_per_job?
  Resque.after_fork do
    Bugsnag.configuration.app_type = "resque"
    Bugsnag.configuration.default_delivery_method = :synchronous
    Bugsnag.configuration.runtime_versions["resque"] = ::Resque::VERSION
  end
else
  Resque.before_first_fork do
    Bugsnag.configuration.app_type = "resque"
    Bugsnag.configuration.default_delivery_method = :synchronous
    Bugsnag.configuration.runtime_versions["resque"] = ::Resque::VERSION
  end
end
