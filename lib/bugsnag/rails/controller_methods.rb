module Bugsnag
  module Rails
    module ControllerMethods
      private
      def notify_bugsnag(exception, custom_data=nil)
        Bugsnag.notify(exception)
        
        # TODO: Pass through custom_data
      end
    end
  end
end