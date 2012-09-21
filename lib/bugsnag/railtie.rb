# Rails 3.x support

require "bugsnag"
require "rails"

module Bugsnag
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/bugsnag.rake"
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
        config.release_stage = ::Rails.env
        config.project_root = ::Rails.root
        config.framework = "Rails: #{::Rails::VERSION::STRING}"

        config.logger ||= ::Rails.logger
      end

      if defined?(::ActionController::Base)
        require "bugsnag/rails/controller_methods"
        ::ActionController::Base.send(:include, Bugsnag::Rails::ControllerMethods)
      end
    end
  end
end
