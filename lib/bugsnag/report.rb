require "json"
require "pathname"
require "bugsnag/stacktrace"

module Bugsnag
  class Report
    NOTIFIER_NAME = "Ruby Bugsnag Notifier"
    NOTIFIER_VERSION = Bugsnag::VERSION
    NOTIFIER_URL = "http://www.bugsnag.com"

    MAX_EXCEPTIONS_TO_UNWRAP = 5

    CURRENT_PAYLOAD_VERSION = "2"

    attr_accessor :api_key
    attr_accessor :app_type
    attr_accessor :app_version
    attr_accessor :configuration
    attr_accessor :context
    attr_accessor :delivery_method
    attr_accessor :exceptions
    attr_accessor :hostname
    attr_accessor :grouping_hash
    attr_accessor :meta_data
    attr_accessor :raw_exceptions
    attr_accessor :release_stage
    attr_accessor :severity
    attr_accessor :user

    def initialize(exception, passed_configuration)
      @should_ignore = false

      self.configuration = passed_configuration

      self.raw_exceptions = generate_raw_exceptions(exception)
      self.exceptions = generate_exception_list

      self.api_key = configuration.api_key
      self.app_type = configuration.app_type
      self.app_version = configuration.app_version
      self.delivery_method = configuration.delivery_method
      self.hostname = configuration.hostname
      self.meta_data = {}
      self.release_stage = configuration.release_stage
      self.severity = "warning"
      self.user = {}
    end

    # Add a new tab to this notification
    def add_tab(name, value)
      return if name.nil?

      if value.is_a? Hash
        meta_data[name.to_s] ||= {}
        meta_data[name.to_s].merge! value
      else
        meta_data["custom"][name.to_s] = value
      end
    end

    # Remove a tab from this notification
    def remove_tab(name)
      return if name.nil?

      meta_data.delete(name.to_s)
    end

    # Build an exception payload
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
          hostname: hostname
        },
        exceptions: exception_list,
        groupingHash: grouping_hash,
        payloadVersion: CURRENT_PAYLOAD_VERSION,
        severity: severity,
        user: user
      }

      # cleanup character encodings
      payload_event = Bugsnag::Cleaner.clean_object_encoding(payload_event)

      # filter out sensitive values in (and cleanup encodings) metaData
      payload_event[:metaData] = Bugsnag::Cleaner.new(configuration.params_filters).clean_object(meta_data)
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

    def ignore?
      @should_ignore
    end

    def request_data
      configuration.request_data
    end

    def ignore!
      @should_ignore = true
    end

    private

    def generate_exception_list
      raw_exceptions.map do |exception|
        {
          errorClass: error_class(exception),
          message: exception.message,
          stacktrace: Stacktrace.new(exception.backtrace).to_a
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
