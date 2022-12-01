module Bugsnag::Utility
  # @api private
  class FeatureFlagDelegate
    def initialize
      # feature flags are stored internally in a hash of "name" => <FeatureFlag>
      # we don't use a Set because new feature flags should overwrite old ones
      # that share a name, but FeatureFlag equality also uses the variant
      @storage = {}
    end

    def initialize_dup(original)
      super

      # copy the internal storage when 'dup' is called
      @storage = @storage.dup
    end

    # Add a feature flag with the given name & variant
    #
    # @param name [String]
    # @param variant [String, nil]
    # @return [void]
    def add(name, variant)
      flag = Bugsnag::FeatureFlag.new(name, variant)

      return unless flag.valid?

      @storage[flag.name] = flag
    end

    # Merge the given array of FeatureFlag instances into the stored feature
    # flags
    #
    # New flags will be appended to the array. Flags with the same name will be
    # overwritten, but their position in the array will not change
    #
    # @param feature_flags [Array<Bugsnag::FeatureFlag>]
    # @return [void]
    def merge(feature_flags)
      feature_flags.each do |flag|
        next unless flag.is_a?(Bugsnag::FeatureFlag)
        next unless flag.valid?

        @storage[flag.name] = flag
      end
    end

    # Remove the stored flag with the given name
    #
    # @param name [String]
    # @return [void]
    def remove(name)
      @storage.delete(name)
    end

    # Remove all the stored flags
    #
    # @return [void]
    def clear
      @storage.clear
    end

    # Get an array of FeatureFlag instances
    #
    # @example
    #   [
    #     <#Bugsnag::FeatureFlag>,
    #     <#Bugsnag::FeatureFlag>,
    #   ]
    #
    # @return [Array<Bugsnag::FeatureFlag>]
    def to_a
      @storage.values
    end

    # Get the feature flags in their JSON representation
    #
    # @example
    #   [
    #     { "featureFlag" => "name", "variant" => "variant" },
    #     { "featureFlag" => "another name" },
    #   ]
    #
    # @return [Array<Hash{String => String}>]
    def as_json
      to_a.map(&:to_h)
    end
  end
end
