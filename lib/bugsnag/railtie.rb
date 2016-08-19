# Rails 3.x hooks

require "rails"
require "bugsnag"
require "bugsnag/middleware/rails3_request"
require "bugsnag/middleware/rack_request"

module Bugsnag
  class Railtie < Rails::Railtie
    rake_tasks do
      require "bugsnag/rake"
      load "bugsnag/tasks/bugsnag.rake"
    end

    # send notifications if a command fails in a 'rails runner' call
    if self.respond_to? :runner
      runner do
        at_exit do
          if $!
            Bugsnag.auto_notify($!)
          end
        end
      end
    end

    config.before_initialize do
      # Configure bugsnag rails defaults
      Bugsnag.configure do |config|
        config.logger = ::Rails.logger
        config.release_stage = ::Rails.env.to_s
        config.project_root = ::Rails.root.to_s
        config.middleware.insert_before Bugsnag::Middleware::Callbacks, Bugsnag::Middleware::Rails3Request
      end

      # Auto-load configuration settings from config/bugsnag.yml if it exists
      config_file = ::Rails.root.join("config", "bugsnag.yml")
      config = YAML.load_file(config_file) if File.exists?(config_file)
      Bugsnag.configure(config[::Rails.env] ? config[::Rails.env] : config) if config

      if defined?(::ActionController::Base)
        require "bugsnag/rails/controller_methods"
        ::ActionController::Base.send(:include, Bugsnag::Rails::ControllerMethods)
      end
      if defined?(ActionController::API)
        ActionController::API.send(:include, Bugsnag::Rails::ControllerMethods)
      end
      if defined?(ActiveRecord::Base)
        require "bugsnag/rails/active_record_rescue"
        ActiveRecord::Base.send(:include, Bugsnag::Rails::ActiveRecordRescue)
      end

      Bugsnag.configuration.app_type = "rails"
    end

    # Configure params_filters after initialization, so that rails initializers
    # may set filter_parameters which will be picked up by Bugsnag.
    config.after_initialize do
      Bugsnag.configure do |config|
        config.params_filters += ::Rails.configuration.filter_parameters.map do |filter|
          case filter
          when String, Symbol
            /\A#{filter}\z/
          else
            filter
          end
        end
      end
    end

    initializer "bugsnag.use_rack_middleware" do |app|
      begin
        app.config.middleware.insert_after ActionDispatch::DebugExceptions, Bugsnag::Rack
      rescue
        app.config.middleware.use Bugsnag::Rack
      end
    end
  end
end
