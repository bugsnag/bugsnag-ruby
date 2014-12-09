require "set"
require "socket"
require "logger"
require "bugsnag/middleware_stack"

module Bugsnag
  class Configuration
    attr_accessor :api_key
    attr_accessor :release_stage
    attr_accessor :notify_release_stages
    attr_accessor :auto_notify
    attr_accessor :use_ssl
    attr_accessor :send_environment
    attr_accessor :send_code
    attr_accessor :project_root
    attr_accessor :app_version
    attr_accessor :app_type
    attr_accessor :params_filters
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
    attr_accessor :timeout
    attr_accessor :hostname
    attr_accessor :delivery_method

    attr_writer :ignore_classes

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
      "Mongoid::Errors::DocumentNotFound",
      "SystemExit",
      "SignalException"
    ].freeze

    DEFAULT_IGNORE_USER_AGENTS = [].freeze

    DEFAULT_DELIVERY_METHOD = :thread_queue

    def initialize
      # Set up the defaults
      self.auto_notify = true
      self.use_ssl = true
      self.send_environment = false
      self.send_code = true
      self.params_filters = Set.new(DEFAULT_PARAMS_FILTERS)
      self.ignore_classes = Set.new(DEFAULT_IGNORE_CLASSES)
      self.ignore_user_agents = Set.new(DEFAULT_IGNORE_USER_AGENTS)
      self.endpoint = DEFAULT_ENDPOINT
      self.hostname = default_hostname
      self.delivery_method = DEFAULT_DELIVERY_METHOD

      # Read the API key from the environment
      self.api_key = ENV["BUGSNAG_API_KEY"]

      # Set up logging
      self.logger = Logger.new(STDOUT)
      self.logger.level = Logger::WARN

      # Configure the bugsnag middleware stack
      self.middleware = Bugsnag::MiddlewareStack.new
      self.middleware.use Bugsnag::Middleware::Callbacks
    end

    # Accept both String and Class instances as an ignored class
    def ignore_classes
      @ignore_classes.map! { |klass| klass.is_a?(Class) ? klass.name : klass }
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

    private

    def default_hostname
      # Don't send the hostname on Heroku
      Socket.gethostname unless ENV["DYNO"]
    end
  end
end
