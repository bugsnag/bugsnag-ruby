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
        # bugsnag_request_data is defined in controller_methods.rb
        Bugsnag.auto_notify(exception, bugsnag_request_data)
        rescue_action_in_public_without_bugsnag(exception)
      end
      
      def rescue_action_locally_with_bugsnag(exception)
        # bugsnag_request_data is defined in controller_methods.rb
        Bugsnag.auto_notify(exception, bugsnag_request_data)
        rescue_action_locally_without_bugsnag(exception)
      end
    end
  end
end