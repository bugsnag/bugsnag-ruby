require "json"
require "pathname"
require "bugsnag/stacktrace"

module Bugsnag
  class Report
    NOTIFIER_NAME = "Ruby Bugsnag Notifier"
    NOTIFIER_VERSION = Bugsnag::VERSION
    NOTIFIER_URL = "https://www.bugsnag.com"

    UNHANDLED_EXCEPTION = "unhandledException"
    UNHANDLED_EXCEPTION_MIDDLEWARE = "unhandledExceptionMiddleware"
    ERROR_CLASS = "errorClass"
    HANDLED_EXCEPTION = "handledException"
    USER_SPECIFIED_SEVERITY = "userSpecifiedSeverity"
    USER_CALLBACK_SET_SEVERITY = "userCallbackSetSeverity"

    MAX_EXCEPTIONS_TO_UNWRAP = 5

    CURRENT_PAYLOAD_VERSION = "4.0"

    attr_reader   :unhandled
    attr_accessor :api_key
    attr_accessor :app_type
    attr_accessor :app_version
    attr_accessor :breadcrumbs
    attr_accessor :configuration
    attr_accessor :context
    attr_accessor :delivery_method
    attr_accessor :exceptions
    attr_accessor :hostname
    attr_accessor :runtime_versions
    attr_accessor :grouping_hash
    attr_accessor :meta_data
    attr_accessor :raw_exceptions
    attr_accessor :release_stage
    attr_accessor :session
    attr_accessor :severity
    attr_accessor :severity_reason
    attr_accessor :user

    ##
    # Initializes a new report from an exception.
    def initialize(exception, passed_configuration, auto_notify=false)
      @should_ignore = false
      @unhandled = auto_notify

      self.configuration = passed_configuration

      self.raw_exceptions = generate_raw_exceptions(exception)
      self.exceptions = generate_exception_list

      self.api_key = configuration.api_key
      self.app_type = configuration.app_type
      self.app_version = configuration.app_version
      self.breadcrumbs = []
      self.delivery_method = configuration.delivery_method
      self.hostname = configuration.hostname
      self.runtime_versions = configuration.runtime_versions
      self.meta_data = {}
      self.release_stage = configuration.release_stage
      self.severity = auto_notify ? "error" : "warning"
      self.severity_reason = auto_notify ? {:type => UNHANDLED_EXCEPTION} : {:type => HANDLED_EXCEPTION}
      self.user = {}
    end

    ##
    # Add a new metadata tab to this notification.
    def add_tab(name, value)
      return if name.nil?

      if value.is_a? Hash
        meta_data[name] ||= {}
        meta_data[name].merge! value
      else
        meta_data["custom"] = {} unless meta_data["custom"]

        meta_data["custom"][name.to_s] = value
      end
    end

    ##
    # Removes a metadata tab from this notification.
    def remove_tab(name)
      return if name.nil?

      meta_data.delete(name)
    end

    ##
    # Builds and returns the exception payload for this notification.
    def as_json
      # Build the payload's exception event
      payload_event = {
        app: {
          version: app_version,
          releaseStage: release_stage,
          type: app_type
        },
        context: context,
        device: {
          hostname: hostname,
          runtimeVersions: runtime_versions
        },
        exceptions: exceptions,
        groupingHash: grouping_hash,
        session: session,
        severity: severity,
        severityReason: severity_reason,
        unhandled: @unhandled,
        user: user
      }

      # cleanup character encodings
      payload_event = Bugsnag::Cleaner.clean_object_encoding(payload_event)

      # filter out sensitive values in (and cleanup encodings) metaData
      filter_cleaner = Bugsnag::Cleaner.new(configuration.meta_data_filters)
      payload_event[:metaData] = filter_cleaner.clean_object(meta_data)
      payload_event[:breadcrumbs] = breadcrumbs.map do |breadcrumb|
        breadcrumb_hash = breadcrumb.to_h
        breadcrumb_hash[:metaData] = filter_cleaner.clean_object(breadcrumb_hash[:metaData])
        breadcrumb_hash
      end

      payload_event.reject! {|k,v| v.nil? }

      # return the payload hash
      {
        :apiKey => api_key,
        :notifier => {
          :name => NOTIFIER_NAME,
          :version => NOTIFIER_VERSION,
          :url => NOTIFIER_URL
        },
        :events => [payload_event]
      }
    end

    ##
    # Returns the headers required for the notification.
    def headers
      {
        "Bugsnag-Api-Key" => api_key,
        "Bugsnag-Payload-Version" => CURRENT_PAYLOAD_VERSION,
        "Bugsnag-Sent-At" => Time.now().utc().strftime('%Y-%m-%dT%H:%M:%S')
      }
    end

    ##
    # Whether this report should be ignored and not sent.
    def ignore?
      @should_ignore
    end

    ##
    # Data set on the configuration to be attached to every error notification.
    def request_data
      configuration.request_data
    end

    ##
    # Tells the client this report should not be sent.
    def ignore!
      @should_ignore = true
    end

    ##
    # Generates a summary to be attached as a breadcrumb
    #
    # @return [Hash] a Hash containing the report's error class, error message, and severity
    def summary
      # Guard against the exceptions array being removed/changed or emptied here
      if exceptions.respond_to?(:first) && exceptions.first
        {
          :error_class => exceptions.first[:errorClass],
          :message => exceptions.first[:message],
          :severity => severity
        }
      else
        {
          :error_class => "Unknown",
          :severity => severity
        }
      end
    end

    private

    def generate_exception_list
      raw_exceptions.map do |exception|
        {
          errorClass: error_class(exception),
          message: exception.message,
          stacktrace: Stacktrace.new(exception.backtrace, configuration).to_a
        }
      end
    end

    def error_class(exception)
      # The "Class" check is for some strange exceptions like Timeout::Error
      # which throw the error class instead of an instance
      (exception.is_a? Class) ? exception.name : exception.class.name
    end

    def generate_raw_exceptions(exception)
      exceptions = []

      ex = exception
      while ex != nil && !exceptions.include?(ex) && exceptions.length < MAX_EXCEPTIONS_TO_UNWRAP

        unless ex.is_a? Exception
          if ex.respond_to?(:to_exception)
            ex = ex.to_exception
          elsif ex.respond_to?(:exception)
            ex = ex.exception
          end
        end

        unless ex.is_a?(Exception) || (defined?(Java::JavaLang::Throwable) && ex.is_a?(Java::JavaLang::Throwable))
          configuration.warn("Converting non-Exception to RuntimeError: #{ex.inspect}")
          ex = RuntimeError.new(ex.to_s)
          ex.set_backtrace caller
        end

        exceptions << ex

        if ex.respond_to?(:cause) && ex.cause
          ex = ex.cause
        elsif ex.respond_to?(:continued_exception) && ex.continued_exception
          ex = ex.continued_exception
        elsif ex.respond_to?(:original_exception) && ex.original_exception
          ex = ex.original_exception
        else
          ex = nil
        end
      end

      exceptions
    end
  end
end
