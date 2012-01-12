module Bugsnag
  module Rails
    module ActionControllerRescue
      def self.included(base)
        base.send(:alias_method, :rescue_action_in_public_without_bugsnag, :rescue_action_in_public)
        base.send(:alias_method, :rescue_action_in_public, :rescue_action_in_public_with_bugsnag)

        base.send(:alias_method, :rescue_action_locally_without_bugsnag, :rescue_action_locally)
        base.send(:alias_method, :rescue_action_locally, :rescue_action_locally_with_bugsnag)
      end

      private
      def rescue_action_in_public_with_bugsnag(exception)
        Bugsnag.notify(exception, :request_data => bugsnag_request_data) unless Bugsnag.configuration.disable_auto
        rescue_action_in_public_without_bugsnag(exception)
      end
      
      def rescue_action_locally_with_bugsnag(exception)
        Bugsnag.notify(exception, :request_data => bugsnag_request_data) unless Bugsnag.configuration.disable_auto
        rescue_action_locally_without_bugsnag(exception)
      end
    end
  end
end