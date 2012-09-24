require "bugsnag/configuration/middleware_configuration"

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
    attr_accessor :middleware

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
      self.middleware = Bugsnag::MiddlewareConfiguration
    end

    def should_notify?
      @notify_release_stages.include?(@release_stage)
    end
  end
end