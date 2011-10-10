require "bugsnag"
require "bugsnag/rails/action_controller_rescue"

module Bugsnag
  module Rails
    def self.initialize
      if defined?(ActionController::Base)
        ActionController::Base.send(:include, Bugsnag::Rails::ActionControllerRescue)
      end

      Bugsnag.configure(true) do |config|
        config.logger = rails_logger
        config.environment_name = RAILS_ENV  if defined?(RAILS_ENV)
        config.project_root = RAILS_ROOT if defined?(RAILS_ROOT)
      end
    end
  end
end

Bugsnag::Rails.initialize