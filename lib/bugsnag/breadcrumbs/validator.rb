require 'bugsnag/breadcrumbs/breadcrumbs'

module Bugsnag::Breadcrumbs
  ##
  # Validates a given breadcrumb before it is stored
  class Validator
    ##
    # @param configuration [Bugsnag::Configuration] The current configuration
    def initialize(configuration)
      @configuration = configuration
    end

    ##
    # Validates a given breadcrumb.
    #
    # @param breadcrumb [Bugsnag::Breadcrumbs::Breadcrumb] the breadcrumb to be validated
    def validate(breadcrumb)
      # Check meta_data hash doesn't contain complex values
      breadcrumb.meta_data = breadcrumb.meta_data.select do |k, v|
        if valid_meta_data_type?(v)
          true
        else
          @configuration.debug("Breadcrumb #{breadcrumb.name} meta_data #{k}:#{v.class} has been dropped for having an invalid data type")
          false
        end
      end

      # Check type is valid, set to manual otherwise
      unless Bugsnag::Breadcrumbs::VALID_BREADCRUMB_TYPES.include?(breadcrumb.type)
        @configuration.debug("Invalid type: #{breadcrumb.type} for breadcrumb: #{breadcrumb.name}, defaulting to #{Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE}")
        breadcrumb.type = Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE
      end

      # If auto is true, check type is in enabled_automatic_breadcrumb_types
      return unless breadcrumb.auto && !@configuration.enabled_automatic_breadcrumb_types.include?(breadcrumb.type)

      @configuration.debug("Automatic breadcrumb of type #{breadcrumb.type} ignored: #{breadcrumb.name}")
      breadcrumb.ignore!
    end

    private

    ##
    # Tests whether the meta_data types are non-complex objects.
    #
    # Acceptable types are String, Symbol, Numeric, TrueClass, FalseClass, and nil.
    #
    # @param value [Object] the object to be type checked
    def valid_meta_data_type?(value)
      value.nil? || value.is_a?(String) || value.is_a?(Symbol) || value.is_a?(Numeric) || value.is_a?(FalseClass) || value.is_a?(TrueClass)
    end
  end
end
