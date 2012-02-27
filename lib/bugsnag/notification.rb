require "httparty"
require "multi_json"

module Bugsnag
  class Notification
    include HTTParty

    NOTIFIER_NAME = "Ruby Bugsnag Notifier"
    NOTIFIER_VERSION = Bugsnag::VERSION
    NOTIFIER_URL = "http://www.bugsnag.com"

    DEFAULT_ENDPOINT = "api.bugsnag.com/notify"

    # HTTParty settings
    headers  "Content-Type" => "application/json"
    default_timeout 5

    # Basic notification attributes
    attr_accessor :exception

    # Attributes from session
    attr_accessor :user_id, :context, :meta_data

    # Attributes from configuration
    attr_accessor :api_key, :params_filters, :stacktrace_filters, 
                  :ignore_classes, :endpoint, :app_version, :release_stage, 
                  :project_root, :use_ssl


    def self.deliver_exception_payload(endpoint, payload_string)
      begin
        response = post(endpoint, {:body => payload_string})
      rescue Exception => e
        Bugsnag.log("Notification to #{endpoint} failed, #{e.inspect}")
      end
    end

    def initialize(exception, opts={})
      self.exception = exception
      opts.reject! {|k,v| v.nil?}.each do |k,v|
        self.send("#{k}=", v) if self.respond_to?("#{k}=")
      end
    end

    def deliver
      # Unless we are using a custom endpoint, use api.bugsnag.com, and work out protocol
      unless self.endpoint
        self.endpoint = (self.use_ssl ? "https://" : "http://") + DEFAULT_ENDPOINT
      end

      Bugsnag.log("Notifying #{self.endpoint} of exception")

      payload = {
        :apiKey => self.api_key,
        :notifier => notifier_identification,
        :errors => [{
          :userId => self.user_id,
          :appVersion => self.app_version,
          :releaseStage => self.release_stage,
          :context => self.context,
          :exceptions => [exception_hash],
          :metaData => self.meta_data
        }.reject {|k,v| v.nil? }]
      }

      self.class.deliver_exception_payload(self.endpoint, MultiJson.encode(payload))
    end

    def ignore?
      self.ignore_classes.include?(error_class(self.exception))
    end


    private
    def notifier_identification
      unless @notifier
        @notifier = {
          :name => NOTIFIER_NAME,
          :version => NOTIFIER_VERSION,
          :url => NOTIFIER_URL
        }
      end

      @notifier
    end

    def stacktrace_hash
      stacktrace = self.exception.backtrace || caller
      stacktrace.map do |trace|
        method = nil
        file, line_str, method_str = trace.split(":")

        # Generate the stacktrace line hash
        trace_hash = {}
        trace_hash[:inProject] = true if self.project_root && file.match(/^#{self.project_root}/)
        trace_hash[:file] = self.stacktrace_filters.inject(file) {|file, proc| proc.call(file) }
        trace_hash[:lineNumber] = line_str.to_i

        # Add a method if we have it
        if method_str
          method_match = /in `([^']+)'/.match(method_str)
          method = method_match.captures.first if method_match
        end
        trace_hash[:method] = method if method && (method =~ /^__bind/).nil?

        if trace_hash[:file] && !trace_hash[:file].empty?
          trace_hash
        else
          nil
        end
      end.compact
    end

    def exception_hash
      {
        :errorClass => error_class(self.exception),
        :message => self.exception.message,
        :stacktrace => stacktrace_hash
      }
    end
    
    def error_class(exception)
      # The "Class" check is for some strange exceptions like Timeout::Error 
      # which throw the error class instead of an instance
      (exception.is_a? Class) ? exception.name : exception.class.name
    end
  end
end