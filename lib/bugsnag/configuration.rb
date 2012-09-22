module Bugsnag
  class Configuration
    attr_accessor :api_key
    attr_accessor :release_stage
    attr_accessor :notify_release_stages
    attr_accessor :auto_notify
    attr_accessor :use_ssl
    attr_accessor :project_root
    attr_accessor :app_version
    attr_accessor :params_filters
    attr_accessor :ignore_classes
    attr_accessor :endpoint
    attr_accessor :logger
    attr_accessor :delay_with

    DEFAULT_PARAMS_FILTERS = [
      "password",
      "password_confirmation"
    ].freeze

    DEFAULT_IGNORE_CLASSES = [
      "ActiveRecord::RecordNotFound",
      "ActionController::RoutingError",
      "ActionController::InvalidAuthenticityToken",
      "CGI::Session::CookieStore::TamperedWithCookie",
      "ActionController::UnknownAction",
      "AbstractController::ActionNotFound",
      "Mongoid::Errors::DocumentNotFound"
    ].freeze

    def initialize
      # Set up the defaults
      self.release_stage = "production"
      self.notify_release_stages = ["production"]
      self.auto_notify = true
      self.use_ssl = false
      self.params_filters = DEFAULT_PARAMS_FILTERS.dup
      self.ignore_classes = DEFAULT_IGNORE_CLASSES.dup
      self.endpoint = "notify.bugsnag.com"
    end

    def should_notify?
      @notify_release_stages.include?(@release_stage)
    end
  end
  
  class RequestConfiguration
    THREAD_LOCAL_NAME = "bugsnag_req_conf"
    #TODO:SM Having this in two places sucks
    REQUEST_CONFIGURATION_NAMES = [:meta_data, :context, :user_id]

    attr_accessor :meta_data
    attr_accessor :context
    attr_accessor :user_id
    
    def initialize
      # Set up the defaults
      self.meta_data = {}
    end
    
    def method_missing(method, *args, &block)
      method = method.to_s  
      if args.length == 1 && method.ends_with?("=")
        method = method[0...-1]
        if args[0].is_a? Hash
          self.meta_data[method] = args[0]
        else
          self.meta_data[:custom] ||= {}
          self.meta_data[:custom][method] = args[0]
        end
      else
        # Warn the user that did nothing
        Bugsnag.warn "Can't configure #{method} with multiple parameters. Dropping #{method} from payload."
      end
    end

    def self.get_instance
      Thread.current[THREAD_LOCAL_NAME] ||= Bugsnag::RequestConfiguration.new
    end
    
    def self.clear_instance
      Thread.current[THREAD_LOCAL_NAME] = nil
    end
  end
end