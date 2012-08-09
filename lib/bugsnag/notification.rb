require "httparty"
require "multi_json"

module Bugsnag
  class Notification
    include HTTParty

    NOTIFIER_NAME = "Ruby Bugsnag Notifier"
    NOTIFIER_VERSION = Bugsnag::VERSION
    NOTIFIER_URL = "http://www.bugsnag.com"

    # HTTParty settings
    headers  "Content-Type" => "application/json"
    default_timeout 5

    def initialize(exception, configuration, request_configuration, opts={})
      @exception = exception
      @configuration = configuration
      @request_configuration = request_configuration
    end

    def deliver
      return unless @configuration.should_notify?
      
      unless @configuration.api_key
        Bugsnag.warn "No API key configured, couldn't notify"
        return
      end
      
      endpoint = (@configuration.use_ssl ? "https://" : "http://") + @configuration.endpoint

      Bugsnag.log("Notifying #{endpoint} of exception")

      payload = {
        :apiKey => @configuration.api_key,
        :notifier => {
          :name => NOTIFIER_NAME,
          :version => NOTIFIER_VERSION,
          :url => NOTIFIER_URL
        },
        :events => [{
          :releaseStage => @configuration.release_stage,
          :appVersion => @configuration.app_version,
          :context => @request_configuration.context,
          :userId => @request_configuration.user_id,
          :exceptions => exception_list,
          :metaData => @request_configuration.meta_data
        }.reject {|k,v| v.nil? }]
      }

      if @request_configuration.extra_data
        payload[:metaData] ||= {}
        payload[:metaData].merge!({
          :extraData => @request_configuration.extra_data
        })
      end

      puts payload.inspect
      begin
        response = self.class.post(endpoint, {:body => MultiJson.dump(payload)})
        puts response
      rescue Exception => e
        Bugsnag.log("Notification to #{endpoint} failed, #{e.inspect}")
        puts e.inspect
      end
    end

    def ignore?
      false # TODO
      # @configuration.ignore_classes.include?(error_class(@exceptions.last))
    end


    private
    def exception_list
      # Unwrap exceptions
      exceptions = []
      ex = @exception
      while ex != nil
        exceptions << ex

        if ex.respond_to?(:continued_exception) && ex.continued_exception
          ex = ex.continued_exception
        elsif ex.respond_to?(:original_exception) && ex.original_exception
          ex = ex.original_exception
        else
          ex = nil
        end
      end
      
      exceptions.map do |exception|
        {
          :errorClass => error_class(exception),
          :message => exception.message,
          :stacktrace => stacktrace(exception)
        }
      end
    end
    
    def error_class(exception)
      # The "Class" check is for some strange exceptions like Timeout::Error 
      # which throw the error class instead of an instance
      (exception.is_a? Class) ? exception.name : exception.class.name
    end

    def stacktrace(exception)
      (exception.backtrace || caller).map do |trace|        
        method = nil
        file, line_str, method_str = trace.split(":")

        next(nil) if file =~ %r{lib/bugsnag}

        # Generate the stacktrace line hash
        trace_hash = {}
        trace_hash[:inProject] = true if @configuration.project_root && file.match(/^#{@configuration.project_root}/) && !file.match(/vendor\//)
        trace_hash[:lineNumber] = line_str.to_i

        # Strip relative path prefixes (./)
        file.sub!(/^\.\//, "")

        # Clean up the file path in the stacktrace
        if defined?(Bugsnag.configuration.project_root) && Bugsnag.configuration.project_root.to_s != '' 
          file.sub!(/#{Bugsnag.configuration.project_root}\//, "")
        end

        # Strip common gem path prefixes
        if defined?(Gem)
          file = Gem.path.inject(file) {|line, path| line.sub(/#{path}\//, "") }
        end

        trace_hash[:file] = file

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
  end
end