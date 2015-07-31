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
      if defined?(ActiveRecord::Base) && Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("4.3")
        unless ActiveRecord::Base.respond_to?(:raise_in_transactional_callbacks) && ActiveRecord::Base.raise_in_transactional_callbacks
          ActiveRecord::Base.send(:include, Bugsnag::Rails::ActiveRecordRescue)
        end
      end

      Bugsnag.configure do |config|
        config.logger ||= rails_logger
        config.release_stage = rails_env if rails_env
        config.project_root = rails_root if rails_root

        config.middleware.insert_before(Bugsnag::Middleware::Callbacks,Bugsnag::Middleware::Rails2Request)
      end

      # Auto-load configuration settings from config/bugsnag.yml if it exists
      config_file = File.join(rails_root, "config", "bugsnag.yml")
      config = YAML.load_file(config_file) if File.exists?(config_file)
      Bugsnag.configure(config[rails_env] ? config[rails_env] : config) if config

      Bugsnag.configuration.app_type = "rails"
    end

    def self.rails_logger
      if defined?(::Rails.logger)
        rails_logger = ::Rails.logger
      elsif defined?(RAILS_DEFAULT_LOGGER)
        rails_logger = RAILS_DEFAULT_LOGGER
      end
    end

    def self.rails_env
      if defined?(::Rails.env)
        ::Rails.env
      elsif defined?(RAILS_ENV)
        RAILS_ENV
      end
    end

    def self.rails_root
      if defined?(::Rails.root)
        ::Rails.root
      elsif defined?(RAILS_ROOT)
        RAILS_ROOT
      end
    end
  end
end

Bugsnag::Rails.initialize
