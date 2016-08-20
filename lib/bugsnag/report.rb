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


    class << self
      def deliver_exception_payload(payload, configuration, delivery_method)
        payload_string = ::JSON.dump(Bugsnag::Helpers.trim_if_needed(payload))
        Bugsnag::Delivery[delivery_method].deliver(url, payload_string, configuration)
      end
    end

    def initialize(exception, configuration, request_data = nil)
      configuration = configuration
      @request_data = request_data
      @user = {}
      @should_ignore = false

      self.api_key = configuration.api_key
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

    # Add a single value as custom data, to this notification
    def add_custom_data(name, value)
      @meta_data[:custom] ||= {}
      @meta_data[:custom][name.to_sym] = value
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

    # Deliver this notification to bugsnag.com Also runs through the middleware as required.
    def deliver
      return unless configuration.should_notify?
      return if ignore?

      # Check we have at least an api_key
      if api_key.nil?
        Bugsnag.warn "No API key configured, couldn't notify"
        return
      elsif api_key !~ API_KEY_REGEX
        Bugsnag.warn "Your API key (#{api_key}) is not valid, couldn't notify"
        return
      end

      configuration.internal_middleware.run(self)

      exceptions.each do |exception|
        if exception.class.include?(Bugsnag::MetaData)
          if exception.bugsnag_user_id.is_a?(String)
            self.user_id = exception.bugsnag_user_id
          end
          if exception.bugsnag_context.is_a?(String)
            self.context = exception.bugsnag_context
          end
        end
      end

      # make meta_data available to public middleware
      @meta_data = generate_meta_data(@exceptions, @overrides)

      # Run the middleware here (including Bugsnag::Middleware::Callbacks)
      # at the end of the middleware stack, execute the actual notification delivery
      configuration.middleware.run(self) do
        # This supports self.ignore! for before_notify_callbacks.
        return if ignore?

        Bugsnag.log("Notifying #{configuration.endpoint} of #{exceptions.last.class}")

        # Deliver the payload
        self.class.deliver_exception_payload(configuration.endpoint, build_exception_payload, configuration)
      end
    end

    # Build an exception payload
    def build_exception_payload
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
      @request_data || Bugsnag.configuration.request_data
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

    # Generate the meta data from both the request configuration, the overrides and the exceptions for this notification
    def generate_meta_data(exceptions, overrides)
      # Copy the request meta data so we dont edit it by mistake
      meta_data = @meta_data.dup

      exceptions.each do |exception|
        if exception.respond_to?(:bugsnag_meta_data) && exception.bugsnag_meta_data
          exception.bugsnag_meta_data.each do |key, value|
            add_to_meta_data key, value, meta_data
          end
        end
      end

      overrides.each do |key, value|
        add_to_meta_data key, value, meta_data
      end

      meta_data
    end

    def add_to_meta_data(key, value, meta_data)
      # If its a hash, its a tab so we can just add it providing its not reserved
      if value.is_a? Hash
        key = key.to_sym

        if meta_data[key]
          # If its a clash, merge with the existing data
          meta_data[key].merge! value
        else
          # Add it as is if its not special
          meta_data[key] = value
        end
      else
        meta_data[:custom] ||= {}
        meta_data[:custom][key] = value
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
