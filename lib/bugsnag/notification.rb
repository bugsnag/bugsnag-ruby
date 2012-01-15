require "httparty"
require "multi_json"

module Bugsnag
  class Notification
    DEFAULT_ENDPOINT = "http://api.bugsnag.com/notify"

    NOTIFIER_NAME = "Ruby Bugsnag Notifier"
    NOTIFIER_VERSION = Bugsnag::VERSION
    NOTIFIER_URL = "http://www.bugsnag.com"
    
    include HTTParty
    headers  "Content-Type" => "application/json"

    attr_accessor :apiKey, :exception, :endpoint, :appVersion, :releaseStage, :projectRoot, :userId, :context, :metaData

    def initialize(api_key, exception, opts={})
      self.apiKey = api_key
      self.exception = exception
      self.endpoint = DEFAULT_ENDPOINT

      opts.reject! {|k,v| v.nil?}.each {|k,v| self.send("#{k}=", v)}
    end

    def deliver
      Bugsnag.log("Notifying #{self.endpoint} of exception")

      payload = {
        :apiKey => self.apiKey,
        :notifier => notifier_identification,
        :errors => [{
          :userId => self.userId,
          :appVersion => self.appVersion,
          :releaseStage => self.releaseStage,
          :context => self.context,
          :exceptions => [exception_hash],
          :metaData => self.metaData
        }.reject {|k,v| v.nil? }]
      }

      begin
        response = self.class.post(self.endpoint, {:body => MultiJson.encode(payload)})
      rescue Exception => e
        Bugsnag.log("Notification to #{self.endpoint} failed, #{e.inspect}")
      end
      
      return response
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
      return [] unless self.exception.backtrace
      self.exception.backtrace.map do |trace|
        method = nil
        file, line_str, method_str = trace.split(":")

        trace_hash = {
          :file => file,
          :lineNumber => line_str.to_i
        }

        if method_str
          method_match = /in `([^']+)'/.match(method_str)
          method = method_match.captures.first if method_match
        end

        trace_hash[:method] = method if method
        trace_hash[:inProject] = true if self.projectRoot && file.match(/^#{self.projectRoot}/)

        trace_hash
      end
    end

    def exception_hash
      {
        :errorClass => self.exception.class.to_s,
        :message => self.exception.message,
        :stacktrace => stacktrace_hash
      }
    end
  end
end