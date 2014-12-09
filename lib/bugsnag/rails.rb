# Rails 2.x hooks
# For Rails 3+ hooks, see railtie.rb

require "bugsnag"
require "bugsnag/rails/controller_methods"
require "bugsnag/rails/action_controller_rescue"
require "bugsnag/rails/active_record_rescue"
require "bugsnag/middleware/rails2_request"
require "bugsnag/middleware/callbacks"

module Bugsnag
  module Rails
    def self.initialize
      if defined?(ActionController::Base)
        ActionController::Base.send(:include, Bugsnag::Rails::ActionControllerRescue)
        ActionController::Base.send(:include, Bugsnag::Rails::ControllerMethods)
      end
      if defined?(ActiveRecord::Base)
        ActiveRecord::Base.send(:include, Bugsnag::Rails::ActiveRecordRescue)
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
        config.release_stage = ::Rails.env.to_s if defined?(::Rails.env)
        config.project_root = ::Rails.root.to_s if defined?(::Rails.root)

        config.middleware.insert_before(Bugsnag::Middleware::Callbacks,Bugsnag::Middleware::Rails2Request)
      end

      # Auto-load configuration settings from config/bugsnag.yml if it exists
      config_file = File.join(RAILS_ROOT, "config", "bugsnag.yml")
      config = YAML.load_file(config_file) if File.exists?(config_file)
      if config
        if defined?(::Rails.env) && config[::Rails.env.to_s]
          Bugsnag.configure(config[::Rails.env.to_s])
        else
          Bugsnag.configure(config)
        end
      end
    end
  end
end

Bugsnag::Rails.initialize
