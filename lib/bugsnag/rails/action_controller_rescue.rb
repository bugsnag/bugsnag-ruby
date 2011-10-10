module Bugsnag
  module Rails
    module ActionControllerRescue
      def self.included(base)
        base.send(:alias_method, :rescue_action_in_public_without_bugsnag, :rescue_action_in_public)
        base.send(:alias_method, :rescue_action_in_public, :rescue_action_in_public_with_bugsnag)
      end

      private
      def rescue_action_in_public_with_bugsnag(exception)
        Bugsnag.notify(exception)
        rescue_action_in_public_without_scepter(exception)
      end
    end
  end
end