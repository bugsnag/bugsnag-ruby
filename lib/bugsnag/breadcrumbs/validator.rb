require 'bugsnag/breadcrumbs/breadcrumbs'

module Bugsnag::Breadcrumbs
  class Validator
    ##
    # Create a Validator object with the current configuration setup.
    def initialize(configuration)
      @configuration = configuration
    end

    ##
    # Validates a given breadcrumb.
    def validate(breadcrumb)
      # Check name length
      if breadcrumb.name.size > Bugsnag::Breadcrumbs::MAX_NAME_LENGTH
        @configuration.warn("Breadcrumb name trimmed to length #{Bugsnag::Breadcrumbs::MAX_NAME_LENGTH}.  Original name: #{breadcrumb.name}")
        breadcrumb.name = breadcrumb.name.slice(0...Bugsnag::Breadcrumbs::MAX_NAME_LENGTH)
      end

      # Check meta_data hash doesn't contain complex values
      breadcrumb.meta_data = breadcrumb.meta_data.clone
      breadcrumb.meta_data.each do |k, v|
        unless valid_meta_data_type?(v)
          @configuration.warn("Breadcrumb #{breadcrumb.name} meta_data #{k}:#{v} has been dropped for having an invalid data type")
          breadcrumb.meta_data[k] = nil
        end
      end
      breadcrumb.meta_data.reject! { |_, v| v.nil? }

      # Check type is valid, set to manual otherwise
      unless Bugsnag::Breadcrumbs::VALID_BREADCRUMB_TYPES.include?(breadcrumb.type)
        @configuration.warn("Invalid type: #{breadcrumb.type} for breadcrumb: #{breadcrumb.name}, defaulting to #{Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE}")
        breadcrumb.type = Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE
      end

      # If auto is true, check type is in automatic_breadcrumb_types
      return unless breadcrumb.auto && !@configuration.automatic_breadcrumb_types.include?(breadcrumb.type)

      @configuration.warn("Automatic breadcrumb of type #{breadcrumb.type} ignored: #{breadcrumb.name}")
      breadcrumb.ignore!
    end

    private

    ##
    # Tests whether the meta_data types are non-complex objects.
    #
    # Acceptable types are String, Numeric, TrueClass, and FalseClass.
    def valid_meta_data_type?(value)
      value.is_a?(String) || value.is_a?(Numeric) || value.is_a?(FalseClass) || value.is_a?(TrueClass)
    end
  end
end
