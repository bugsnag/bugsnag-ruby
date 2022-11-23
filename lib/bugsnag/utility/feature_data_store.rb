module Bugsnag::Utility
  # @abstract Requires a #feature_flag_delegate method returning a
  #   {Bugsnag::Utility::FeatureFlagDelegate}
  module FeatureDataStore
    # Add a feature flag with the given name & variant
    #
    # @param name [String]
    # @param variant [String, nil]
    # @return [void]
    def add_feature_flag(name, variant = nil)
      feature_flag_delegate.add(name, variant)
    end

    # Merge the given array of FeatureFlag instances into the stored feature
    # flags
    #
    # New flags will be appended to the array. Flags with the same name will be
    # overwritten, but their position in the array will not change
    #
    # @param feature_flags [Array<Bugsnag::FeatureFlag>]
    # @return [void]
    def add_feature_flags(feature_flags)
      feature_flag_delegate.merge(feature_flags)
    end

    # Remove the stored flag with the given name
    #
    # @param name [String]
    # @return [void]
    def clear_feature_flag(name)
      feature_flag_delegate.remove(name)
    end

    # Remove all the stored flags
    #
    # @return [void]
    def clear_feature_flags
      feature_flag_delegate.clear
    end
  end
end
