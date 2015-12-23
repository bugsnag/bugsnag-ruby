require 'uri'

module Bugsnag
  module Helpers
    MAX_STRING_LENGTH = 4096

    def self.reduce_hash_size(hash)
      return {} unless hash.is_a?(Hash)
      hash.inject({}) do |h, (k,v)|
        if v.is_a?(Hash)
          h[k] = reduce_hash_size(v)
        elsif v.is_a?(Array) || v.is_a?(Set)
          h[k] = v.map {|el| reduce_hash_size(el) }
        else
          val = v.to_s
          val = val.slice(0, MAX_STRING_LENGTH) + "[TRUNCATED]" if val.length > MAX_STRING_LENGTH
          h[k] = val
        end

        h
      end
    end

    def self.flatten_meta_data(overrides)
      return nil unless overrides

      meta_data = overrides.delete(:meta_data)
      if meta_data.is_a?(Hash)
        overrides.merge(meta_data)
      else
        overrides
      end
    end
  end
end
