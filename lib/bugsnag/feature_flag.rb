module Bugsnag
  class FeatureFlag
    # Get the name of this feature flag
    #
    # @return [String]
    attr_reader :name

    # Get the variant of this feature flag
    #
    # @return [String, nil]
    attr_reader :variant

    # @param name [String] The name of this feature flags
    # @param variant [String, nil] An optional variant for this flag
    def initialize(name, variant = nil)
      @name = name
      @variant = coerce_variant(variant)
    end

    def ==(other)
      self.class == other.class && @name == other.name && @variant == other.variant
    end

    def hash
      [@name, @variant].hash
    end

    # Convert this flag to a hash
    #
    # @example With no variant
    #   { "featureFlag" => "name" }
    #
    # @example With a variant
    #   { "featureFlag" => "name", "variant" => "variant" }
    #
    # @return [Hash{String => String}]
    def to_h
      if @variant.nil?
        { "featureFlag" => @name }
      else
        { "featureFlag" => @name, "variant" => @variant }
      end
    end

    # Check if this flag is valid, i.e. has a name that's a String and a variant
    # that's either nil or a String
    #
    # @return [Boolean]
    def valid?
      @name.is_a?(String) &&
        !@name.empty? &&
        (@variant.nil? || @variant.is_a?(String))
    end

    private

    # Coerce this variant into a valid value (String or nil)
    #
    # If the variant is not already a string or nil, we use #to_s to coerce it.
    # If #to_s raises, the variant will be set to nil
    #
    # @param variant [Object]
    # @return [String, nil]
    def coerce_variant(variant)
      if variant.nil? || variant.is_a?(String)
        variant
      else
        variant.to_s
      end
    rescue StandardError
      nil
    end
  end
end
