# Rails 3.x hooks

require "rails"
require "bugsnag"
require "bugsnag/middleware/rails3_request"

module Bugsnag
  class Railtie < Rails::Railtie
    rake_tasks do
      load "bugsnag/tasks/bugsnag.rake"
    end

    config.before_initialize do
      # Configure bugsnag rails defaults
      Bugsnag.configure do |config|
        config.logger = Rails.logger
        config.release_stage = Rails.env.to_s
        config.project_root = Rails.root.to_s
        config.params_filters += Rails.configuration.filter_parameters
      end

      # Auto-load configuration settings from config/bugsnag.yml if it exists
      config_file = Rails.root.join("config", "bugsnag.yml")
      config = YAML.load_file(config_file) if File.exists?(config_file)
      Bugsnag.configure(config[Rails.env] ? config[Rails.env] : config) if config

      if defined?(::ActionController::Base)
        require "bugsnag/rails/controller_methods"
        ::ActionController::Base.send(:include, Bugsnag::Rails::ControllerMethods)
      end
    end

    initializer "bugsnag.use_rack_middleware" do |app|
      begin
        app.config.middleware.insert_after ActionDispatch::DebugExceptions, "Bugsnag::Rack"
      rescue
        app.config.middleware.use "Bugsnag::Rack"
      end
    end

    config.after_initialize do
      Bugsnag.configure do |config|
        config.middleware.use Bugsnag::Middleware::Rails3Request
      end
    end
  end
end