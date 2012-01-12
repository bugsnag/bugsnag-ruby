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
        auto_notify(exception) unless Bugsnag.configuration.disable_auto_notification
        rescue_action_in_public_without_bugsnag(exception)
      end
      
      def rescue_action_locally_with_bugsnag(exception)
        auto_notify(exception) unless Bugsnag.configuration.disable_auto_notification
        rescue_action_locally_without_bugsnag(exception)
      end
      
      def auto_notify(exception)
        Bugsnag.notify(exception, {
          :user_id => bugsnag_session_id,
          :web_environment => bugsnag_request_data
        })
      end
    end
  end
end