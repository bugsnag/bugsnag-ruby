require "httparty"
require "multi_json"
require "pathname"

module Bugsnag
  class Notification
    include HTTParty

    NOTIFIER_NAME = "Ruby Bugsnag Notifier"
    NOTIFIER_VERSION = Bugsnag::VERSION
    NOTIFIER_URL = "http://www.bugsnag.com"

    API_KEY_REGEX = /[0-9a-f]{32}/i

    MAX_EXCEPTIONS_TO_UNWRAP = 5

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
          if payload_string.length > 128000
            payload[:events].each {|e| e[:metaData] = Bugsnag::Helpers.reduce_hash_size(e[:metaData])}
            payload_string = Bugsnag::Helpers.dump_json(payload)
          end

          response = post(endpoint, {:body => payload_string})
        rescue StandardError => e
          # KLUDGE: Since we don't re-raise http exceptions, this breaks rspec
          raise if e.class.to_s == "RSpec::Expectations::ExpectationNotMetError"

          Bugsnag.warn("Notification to #{endpoint} failed, #{e.inspect}")
        end
      end
    end

    def initialize(exception, configuration, overrides = nil, request_data = nil)
      @configuration = configuration
      @overrides = Bugsnag::Helpers.flatten_meta_data(overrides) || {}
      @request_data = request_data
      @meta_data = {}
      
      # Unwrap exceptions
      @exceptions = []
      ex = exception
      while ex != nil && !@exceptions.include?(ex) && @exceptions.length < MAX_EXCEPTIONS_TO_UNWRAP
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

    # Deliver this notification to bugsnag.com Also runs through the middleware as required.
    def deliver
      return unless @configuration.should_notify?

      # Check we have at least an api_key
      if @configuration.api_key.nil?
        Bugsnag.warn "No API key configured, couldn't notify"
        return
      elsif (@configuration.api_key =~ API_KEY_REGEX).nil?
        Bugsnag.warn "Your API key (#{@configuration.api_key}) is not valid, couldn't notify"
        return
      end

      # Warn if no release_stage is set
      Bugsnag.warn "You should set your app's release_stage (see https://bugsnag.com/docs/notifiers/ruby#release_stage)." unless @configuration.release_stage


      @meta_data = {}
      
      # Run the middleware here, at the end of the middleware stack, execute the actual delivery
      @configuration.middleware.run(self) do
        # Now override the required fields
        [:user_id, :context].each do |symbol|
          if @overrides[symbol]
            self.send("#{symbol}=", @overrides[symbol] )
            @overrides.delete symbol
          end
        end

        # Build the endpoint url
        endpoint = (@configuration.use_ssl ? "https://" : "http://") + @configuration.endpoint
        Bugsnag.log("Notifying #{endpoint} of #{@exceptions.last.class}")

        # Build the payload's exception event
        payload_event = {
          :releaseStage => @configuration.release_stage,
          :appVersion => @configuration.app_version,
          :context => self.context,
          :userId => self.user_id,
          :exceptions => exception_list,
          :metaData => Bugsnag::Helpers.cleanup_obj(generate_meta_data(@overrides), @configuration.params_filters)
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
    end

    def ignore?
      @configuration.ignore_classes.include?(error_class(@exceptions.last))
    end

    def request_data
      @request_data || Bugsnag.configuration.request_data
    end
    
    def exceptions
      @exceptions
    end

    private
    # Generate the meta data from both the request configuration and the overrides for this notification
    def generate_meta_data(overrides)
      # Copy the request meta data so we dont edit it by mistake
      meta_data = @meta_data.dup
      
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
          meta_data[:custom] ||= {}
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

        # Expand relative paths
        file = Pathname.new(file).realpath.to_s rescue file

        # Generate the stacktrace line hash
        trace_hash = {}
        trace_hash[:inProject] = true if @configuration.project_root && file.match(/^#{@configuration.project_root}/) && !file.match(/vendor\//)
        trace_hash[:lineNumber] = line_str.to_i

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