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
    
    attr_accessor :context
    attr_accessor :user_id
    
    class << self
      def deliver_exception_payload(endpoint, payload)
        begin
          payload_string = Bugsnag::Helpers.dump_json(payload)
        
          # If the payload is going to be too long, we trim the hashes to send 
          # a minimal payload instead
          if payload_string.length > 512000
            Bugsnag::Helpers.reduce_hash_size(payload)
            payload_string = Bugsnag::Helpers.dump_json(payload)
          end
        
          response = post(endpoint, {:body => payload_string})
        rescue Exception => e
          Bugsnag.log("Notification to #{endpoint} failed, #{e.inspect}")
        end
      end
    end

    def initialize(exception, configuration, overrides = {})
      @configuration = configuration
      @overrides = overrides.with_indifferent_access
      
      # Unwrap exceptions
      @exceptions = []
      ex = exception
      while ex != nil
        @exceptions << ex

        if ex.respond_to?(:continued_exception) && ex.continued_exception
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
      @metadata[:custom] ||= {}
      @metadata[:custom][name] = value
    end

    # Add a new tab to this notification
    def add_tab(name, value)
      if value.is_a? Hash
        @metadata[name] = value
      else
        self.add_custom_data(name, value)
        Bugsnag.warn "Adding a tab requires a hash, adding to custom tab instead"
      end
    end

    # Deliver this notification to bugsnag.com Also runs through the middleware as required.
    def deliver
      return unless @configuration.should_notify?

      # Check we have at least and api_key
      unless @configuration.api_key
        Bugsnag.warn "No API key configured, couldn't notify"
        return
      end
      
      @metadata = {}.with_indifferent_access
      
      # Run the middleware here - the final middleware will always call self.send
      @configuration.middleware.run Bugsnag::RequestData.get_instance.request_data, @exceptions, self
    end
    
    def send
      puts @metadata.inspect
      
      # Now override the required fields
      [:user_id, :context].each do |symbol|
        if @overrides[symbol]
          self.send("context=", @overrides[symbol] )
          @overrides.delete symbol
        end
      end

      # Build the endpoint url
      endpoint = (@configuration.use_ssl ? "https://" : "http://") + @configuration.endpoint
      Bugsnag.log("Notifying #{endpoint} of exception")

      # Build the payload's exception event
      payload_event = {
        :releaseStage => @configuration.release_stage,
        :appVersion => @configuration.app_version,
        :context => self.context,
        :userId => self.user_id,
        :exceptions => exception_list,
        :metaData => Bugsnag::Helpers.cleanup_hash(generate_meta_data(@overrides), @configuration.params_filters)
      }.reject {|k,v| v.nil? }

      # Build the payload hash
      payload = {
        :apiKey => @configuration.api_key,
        :notifier => {
          :name => NOTIFIER_NAME,
          :version => NOTIFIER_VERSION,
          :url => NOTIFIER_URL
        },
        :events => [payload_event]
      }

      self.class.deliver_exception_payload(endpoint, payload)
    end

    def ignore?
      @configuration.ignore_classes.include?(error_class(@exceptions.last))
    end


    private
    # Generate the meta data from both the request configuration and the overrides for this notification
    def generate_meta_data(overrides)
      # Copy the request meta data so we dont edit it by mistake
      meta_data = (@meta_data.try(:dup) || {}).with_indifferent_access
      
      overrides.each do |key, value|
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
          meta_data[:custom] ||= {}.with_indifferent_access
          meta_data[:custom][key] = value
        end
      end
      
      meta_data
    end
    
    def exception_list      
      @exceptions.map do |exception|
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