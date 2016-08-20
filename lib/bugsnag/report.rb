require "json"
require "pathname"

module Bugsnag
  class Report
    NOTIFIER_NAME = "Ruby Bugsnag Notifier"
    NOTIFIER_VERSION = Bugsnag::VERSION
    NOTIFIER_URL = "http://www.bugsnag.com"

    API_KEY_REGEX = /[0-9a-f]{32}/i

    MAX_EXCEPTIONS_TO_UNWRAP = 5

    CURRENT_PAYLOAD_VERSION = "2"

    attr_reader :user
    attr_accessor :api_key
    attr_accessor :configuration
    attr_accessor :context
    attr_accessor :delivery_method
    attr_accessor :grouping_hash
    attr_accessor :meta_data
    attr_accessor :severity

    def initialize(exception, configuration)
      @user = {}
      @should_ignore = false

      self.api_key = configuration.api_key
      self.configuration = configuration
      self.delivery_method = configuration.delivery_method
      self.meta_data = {}
      self.severity = "warning"

      # Unwrap exceptions
      @exceptions = []

      ex = exception
      while ex != nil && !@exceptions.include?(ex) && @exceptions.length < MAX_EXCEPTIONS_TO_UNWRAP

        unless ex.is_a? Exception
          if ex.respond_to?(:to_exception)
            ex = ex.to_exception
          elsif ex.respond_to?(:exception)
            ex = ex.exception
          end
        end

        unless ex.is_a?(Exception) || (defined?(Java::JavaLang::Throwable) && ex.is_a?(Java::JavaLang::Throwable))
          Bugsnag.warn("Converting non-Exception to RuntimeError: #{ex.inspect}")
          ex = RuntimeError.new(ex.to_s)
          ex.set_backtrace caller
        end

        @exceptions << ex

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
    end

    # Add a new tab to this notification
    def add_tab(name, value)
      return if name.nil?

      if value.is_a? Hash
        @meta_data[name.to_sym] ||= {}
        @meta_data[name.to_sym].merge! value
      else
        self.add_custom_data(name, value)
        Bugsnag.warn "Adding a tab requires a hash, adding to custom tab instead (name=#{name})"
      end
    end

    # Remove a tab from this notification
    def remove_tab(name)
      return if name.nil?

      @meta_data.delete(name.to_sym)
    end

    def user=(user = {})
      return unless user.is_a? Hash
      @user.merge!(user).delete_if{|k,v| v == nil}
    end

    # Build an exception payload
    def as_json
      # Build the payload's exception event
      payload_event = {
        :app => {
          :version => configuration.app_version,
          :releaseStage => configuration.release_stage,
          :type => configuration.app_type
        },
        :context => self.context,
        :user => @user,
        :payloadVersion => CURRENT_PAYLOAD_VERSION,
        :exceptions => exception_list,
        :severity => self.severity,
        :groupingHash => self.grouping_hash,
      }

      payload_event[:device] = {:hostname => configuration.hostname} if configuration.hostname

      # cleanup character encodings
      payload_event = Bugsnag::Cleaner.clean_object_encoding(payload_event)

      # filter out sensitive values in (and cleanup encodings) metaData
      payload_event[:metaData] = Bugsnag::Cleaner.new(configuration.params_filters).clean_object(@meta_data)
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
      @should_ignore || ignore_exception_class? || ignore_user_agent?
    end

    def request_data
      @configuration.request_data
    end

    def exceptions
      @exceptions
    end

    def ignore!
      @should_ignore = true
    end

    private

    def ignore_exception_class?
      @exceptions.any? do |ex|
        ancestor_chain = ex.class.ancestors.select { |ancestor| ancestor.is_a?(Class) }.map { |ancestor| error_class(ancestor) }.to_set

        configuration.ignore_classes.any? do |to_ignore|
          to_ignore.is_a?(Proc) ? to_ignore.call(ex) : ancestor_chain.include?(to_ignore)
        end
      end
    end

    def ignore_user_agent?
      if configuration.request_data && configuration.request_data[:rack_env] && (agent = configuration.request_data[:rack_env]["HTTP_USER_AGENT"])
        configuration.ignore_user_agents.any? do |to_ignore|
          agent =~ to_ignore
        end
      end
    end

    def exception_list
      @exceptions.map do |exception|
        {
          :errorClass => error_class(exception),
          :message => exception.message,
          :stacktrace => stacktrace(exception.backtrace)
        }
      end
    end

    def error_class(exception)
      # The "Class" check is for some strange exceptions like Timeout::Error
      # which throw the error class instead of an instance
      (exception.is_a? Class) ? exception.name : exception.class.name
    end
  end
end
