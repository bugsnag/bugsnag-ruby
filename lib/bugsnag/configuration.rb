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
      @release_stage = "production"
      @notify_release_stages = ["production"]
      @auto_notify = true
      @use_ssl = false
      @params_filters = DEFAULT_PARAMS_FILTERS.dup
      @ignore_classes = DEFAULT_IGNORE_CLASSES.dup
      @endpoint = "notify.bugsnag.com"
    end

    def should_notify?
      @notify_release_stages.include?(@release_stage)
    end
  end
  
  class RequestConfiguration
    THREAD_LOCAL_NAME = "bugsnag"

    attr_accessor :context
    attr_accessor :user_id
    attr_accessor :custom_data
    
    attr_accessor :meta_data_callback

    def self.get_instance
      Thread.current[THREAD_LOCAL_NAME] ||= Bugsnag::RequestConfiguration.new
    end
    
    def self.clear_instance
      Thread.current[THREAD_LOCAL_NAME] = nil
    end

    def set_meta_data(tab_name, metadata)
      @meta_data ||= {}
      @meta_data[tab_name] = Bugsnag::Helpers.cleanup_hash(Bugsnag::Helpers.apply_filters(metadata, Bugsnag.configuration.params_filters))
    end
    
    def meta_data
      @meta_data
    end
  end
end