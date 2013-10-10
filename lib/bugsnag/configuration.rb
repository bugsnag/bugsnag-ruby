require "set"
require "logger"
require "bugsnag/middleware_stack"

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
    attr_accessor :ignore_user_agents
    attr_accessor :endpoint
    attr_accessor :logger
    attr_accessor :middleware
    attr_accessor :delay_with_resque
    attr_accessor :debug
    attr_accessor :proxy_host
    attr_accessor :proxy_port
    attr_accessor :proxy_user
    attr_accessor :proxy_password

    THREAD_LOCAL_NAME = "bugsnag_req_data"

    DEFAULT_ENDPOINT = "notify.bugsnag.com"

    DEFAULT_PARAMS_FILTERS = ["password", "secret", "rack.request.form_vars"].freeze

    DEFAULT_IGNORE_CLASSES = [
      "ActiveRecord::RecordNotFound",
      "ActionController::RoutingError",
      "ActionController::InvalidAuthenticityToken",
      "CGI::Session::CookieStore::TamperedWithCookie",
      "ActionController::UnknownAction",
      "AbstractController::ActionNotFound",
      "Mongoid::Errors::DocumentNotFound"
    ].freeze

    DEFAULT_IGNORE_USER_AGENTS = [].freeze

    def initialize
      # Set up the defaults
      self.auto_notify = true
      self.use_ssl = false
      self.params_filters = Set.new(DEFAULT_PARAMS_FILTERS)
      self.ignore_classes = Set.new(DEFAULT_IGNORE_CLASSES)
      self.ignore_user_agents = Set.new(DEFAULT_IGNORE_USER_AGENTS)
      self.endpoint = DEFAULT_ENDPOINT

      # Read the API key from the environment
      self.api_key = ENV["BUGSNAG_API_KEY"]

      # Set up logging
      self.logger = Logger.new(STDOUT)
      self.logger.level = Logger::WARN

      # Configure the bugsnag middleware stack
      self.middleware = Bugsnag::MiddlewareStack.new
      self.middleware.use Bugsnag::Middleware::Callbacks
    end

    # Tries to ensure bugsnag has been configured in the case where initializers etc
    # have not been run. Returns a boolean to indicate whether bugsnag has been configured.
    def auto_configure
      if configuration.api_key.nil? || configuration.api_key.empty?
        # Try and load Rails initializer
        if defined?(Rails) && Rails.root
          begin
            require Rails.root.join('config/initializers/bugsnag')
          rescue Exception => e
            load_config_from_yaml 
          end
        end
      end

      return !configuration.api_key.nil? && !configuration.api_key.empty?
    end

    def load_config_from_yaml
      if defined?(RAILS_ROOT)
        config_file = File.join(RAILS_ROOT, "config", "bugsnag.yml")
        environment = RAILS_ENV
      elsif defined?(Rails) && Rails.root
        config_file = Rails.root.join("config", "bugsnag.yml")
        environment = Rails.env
      end
      if config_file && environment
        config = YAML.load_file(config_file) if File.exists?(config_file)
        Bugsnag.configure(config[environment] ? config[environment] : config) if config
      end
    end

    def should_notify?
      @release_stage.nil? || @notify_release_stages.nil? || @notify_release_stages.include?(@release_stage)
    end

    def request_data
      Thread.current[THREAD_LOCAL_NAME] ||= {}
    end

    def set_request_data(key, value)
      self.request_data[key] = value
    end
    
    def unset_request_data(key, value)
      self.request_data.delete(key)
    end

    def clear_request_data
      Thread.current[THREAD_LOCAL_NAME] = nil
    end
  end
end
