# Rails 2.x hooks
# For Rails 3+ hooks, see railtie.rb

require "bugsnag"
require "bugsnag/rails/controller_methods"
require "bugsnag/rails/action_controller_rescue"
require "bugsnag/middleware/rails2_request"
require "bugsnag/middleware/callbacks"

module Bugsnag
  module Rails
    def self.initialize
      if defined?(ActionController::Base)
        ActionController::Base.send(:include, Bugsnag::Rails::ActionControllerRescue)
        ActionController::Base.send(:include, Bugsnag::Rails::ControllerMethods)
      end

      # Try to find where to log to
      rails_logger = nil
      if defined?(::Rails.logger)
        rails_logger = ::Rails.logger
      elsif defined?(RAILS_DEFAULT_LOGGER)
        rails_logger = RAILS_DEFAULT_LOGGER
      end

      Bugsnag.configure do |config|
        config.logger ||= rails_logger
        config.release_stage = RAILS_ENV if defined?(RAILS_ENV)
        config.project_root = RAILS_ROOT if defined?(RAILS_ROOT)

        config.middleware.insert_before(Bugsnag::Middleware::Callbacks,Bugsnag::Middleware::Rails2Request)
      end

      # Auto-load configuration settings from config/bugsnag.yml if it exists
      Bugsnag.configuration.load_config_from_yaml
    end
  end
end

Bugsnag::Rails.initialize