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
      #Check message length
      if breadcrumb.message.size > MAX_MESSAGE_LENGTH
        @configuration.warn("Breadcrumb message trimmed to length #{MAX_MESSAGE_LENGTH}.  Original message: #{breadcrumb.message}")
        breadcrumb.message.slice!(MAX_MESSAGE_LENGTH...breadcrumb.message.size)
      end

      #Check meta_data hash doesn't contain complex values
      unless valid_meta_data_types?(breadcrumb.meta_data)
        @configuration.warn("Breadcrumb #{breadcrumb.message} meta data contains values other than strings, numbers, or booleans, dropping: #{breadcrumb.meta_data}")
        breadcrumb.meta_data = {}
      end

      #Check type is valid, set to manual otherwise
      unless VALID_BREADCRUMB_TYPES.include?(breadcrumb.type)
        @configuration.warn("Invalid type: #{breadcrumb.type} for breadcrumb: #{breadcrumb.message}, defaulting to #{MANUAL_BREADCRUMB_TYPE}")
        breadcrumb.type = MANUAL_BREADCRUMB_TYPE
      end

      #If auto is true, check type is in automatic_breadcrumb_types
      if breadcrumb.auto && !@configuration.automatic_breadcrumb_types.include?(breadcrumb.type)
        @configuration.warn("Automatic breadcrumb of type #{breadcrumb.type} ignored: #{breadcrumb.message}")
        breadcrumb.ignore!
      end
    end

    private

    ##
    # Tests whether the meta_data types are non-complex objects.
    #
    # Acceptable types are String, Numeric, TrueClass, and FalseClass.
    def valid_meta_data_types?(meta_data)
      meta_data.all? { |k, value| value.is_a?(String) || value.is_a?(Numeric) || value.is_a?(FalseClass) || value.is_a?(TrueClass) }
    end
  end
end