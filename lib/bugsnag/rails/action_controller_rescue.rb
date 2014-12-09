# Rails 2.x only
module Bugsnag::Rails
  module ActionControllerRescue
    def self.included(base)
      base.extend(ClassMethods)

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

    module ClassMethods

      def self.extended(base)
        base.singleton_class.class_eval do
          alias_method_chain :filter_parameter_logging, :bugsnag
        end
      end

      # Rails 2 does parameter filtering via a controller configuration method
      # that dynamically defines a method on the controller, so the configured
      # parameters aren't easily accessible. Intercept these parameters as
      # they're configured so that the Bugsnag configuration can take them
      # into account.
      #
      def filter_parameter_logging_with_bugsnag(*filter_words, &block)
        if filter_words.length > 0
          Bugsnag.configure do |config|
            # Use the same regular expression that Rails parameter filtering uses.
            config.params_filters << Regexp.new(filter_words.collect{ |s| s.to_s }.join('|'), true)
          end
        end
        filter_parameter_logging_without_bugsnag(*filter_words, &block)
      end
    end

  end
end