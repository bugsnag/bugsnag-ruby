module Bugsnag
  module Rails
    module ControllerMethods
      private
      def notify_bugsnag(exception, custom_data=nil)
        Bugsnag.warn "DEPRECATED METHOD: notify_bugsnag is deprecated and will be removed in the future. Please use Bugsnag.notify instead" if Bugsnag.configuration.release_stage != "production"
        overrides = {}
        overrides[:custom] = custom_data if custom_data
        Bugsnag.notify(exception, overrides)
      end
    end
  end
end