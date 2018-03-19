module Bugsnag
  module Helpers
    class << self
      ##
      # Merges r_hash into l_hash recursively, favouring the values in r_hash.
      #
      # Returns a new array consisting of the merged values
      def deep_merge(l_hash, r_hash)
        l_hash.merge(r_hash) do |_key, l_val, r_val|
          if l_val.is_a?(Hash) && r_val.is_a?(Hash)
            deep_merge(l_val, r_val)
          elsif l_val.is_a?(Array) && r_val.is_a?(Array)
            l_val.concat(r_val)
          else
            r_val
          end
        end
      end

      ##
      # Merges r_hash into l_hash recursively, favouring the values in r_hash.
      #
      # Overwrites the values in the existing l_hash
      def deep_merge!(l_hash, r_hash)
        l_hash.merge!(r_hash) do |_key, l_val, r_val|
          if l_val.is_a?(Hash) && r_val.is_a?(Hash)
            deep_merge(l_val, r_val)
          elsif l_val.is_a?(Array) && r_val.is_a?(Array)
            l_val.concat(r_val)
          else
            r_val
          end
        end
      end
    end
  end
end
