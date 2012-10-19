# Rails 2.x only
module Bugsnag::Rails
  module ActionControllerRescue
    def self.included(base)
      # Hook into rails exception rescue stack
      base.send(:alias_method, :rescue_action_in_public_without_bugsnag, :rescue_action_in_public)
      base.send(:alias_method, :rescue_action_in_public, :rescue_action_in_public_with_bugsnag)

      base.send(:alias_method, :rescue_action_locally_without_bugsnag, :rescue_action_locally)
      base.send(:alias_method, :rescue_action_locally, :rescue_action_locally_with_bugsnag)

      # Run filters on requests to capture request data
      base.send(:prepend_before_filter, :set_bugsnag_request_data)
    end

    private
    def set_bugsnag_request_data
      Bugsnag.clear_request_data
      Bugsnag.set_request_data(:rails2_request, request)
    end

    def rescue_action_in_public_with_bugsnag(exception)
      Bugsnag.auto_notify(exception)

      rescue_action_in_public_without_bugsnag(exception)
    end

    def rescue_action_locally_with_bugsnag(exception)
      Bugsnag.auto_notify(exception)

      rescue_action_locally_without_bugsnag(exception)
    end
  end
end