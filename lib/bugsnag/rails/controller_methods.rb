module Bugsnag::Rails
  module ControllerMethods
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      private      
      def before_bugsnag_notify(*methods, &block)
        _add_bugsnag_notify_callback(:rails_before_callbacks, *methods, &block)
      end

      def after_bugsnag_notify(*methods, &block)
        _add_bugsnag_notify_callback(:rails_after_callbacks, *methods, &block)
      end

      def _add_bugsnag_notify_callback(callback_key, *methods, &block)
        options = methods.last.is_a?(Hash) ? methods.pop : {}

        before_filter(options) do |controller|
          request_data = Bugsnag.configuration.request_data
          request_data[callback_key] ||= []

          # Set up "method symbol" callbacks
          methods.each do |method_symbol|
            request_data[callback_key] << lambda { |notification|
              self.send(method_symbol, notification)
            }
          end

          # Set up "block" callbacks
          request_data[callback_key] << lambda { |notification|
            controller.instance_exec(notification, &block)
          } if block_given?
        end
      end
    end

    private
    def notify_bugsnag(exception, custom_data=nil)
      Bugsnag.warn "DEPRECATED METHOD: notify_bugsnag is deprecated and will be removed in the future. Please use Bugsnag.notify instead" if Bugsnag.configuration.release_stage != "production"

      overrides = {}
      overrides[:custom] = custom_data if custom_data
      Bugsnag.notify(exception, overrides)
    end
  end
end