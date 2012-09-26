module Bugsnag::Rails
  module ControllerMethods
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      private
      def before_bugsnag_notify(*methods, &block)
        options = methods.last.is_a?(Hash) ? methods.pop : {}

        before_filter(options) do |controller|
          request_data = Bugsnag.configuration.request_data
          request_data[:rails_before_callbacks] ||= []

          # Set up "method symbol" callbacks
          methods.each do |method_symbol|
            request_data[:rails_before_callbacks] << lambda { |notification, exceptions|
              self.send(method_symbol, notification, exceptions)
            }
          end

          # Set up "block" callbacks
          request_data[:rails_before_callbacks] << lambda { |notification, exceptions|
            controller.instance_exec(notification, exceptions, &block)
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