# Rails 2.x support

require "bugsnag"
require "bugsnag/rails/controller_methods"
require "bugsnag/rails/action_controller_rescue"

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
        config.logger = rails_logger
        config.release_stage = RAILS_ENV  if defined?(RAILS_ENV)
        config.project_root = RAILS_ROOT if defined?(RAILS_ROOT)
        config.framework = "Rails: #{::Rails::VERSION::STRING}" if defined?(::Rails::VERSION)
      end
    end
  end
end

Bugsnag::Rails.initialize