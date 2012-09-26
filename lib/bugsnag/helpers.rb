module HTTParty
  class Parser
    def json
      MultiJson.decode(body)
    end
  end
end

module Bugsnag
  module Helpers
    MAX_STRING_LENGTH = 4096

    def self.cleanup_hash(hash, filters = nil)
      new_hash = {}

      hash.each do |k,v|
        if filters && filters.any? {|f| k.to_s.include?(f.to_s)}
          new_hash[k] = "[FILTERED]"
        elsif v.is_a?(Hash)
          new_hash[k] = cleanup_hash(v, filters)
        else
          val = v.to_s
          new_hash[k] = val unless val =~ /^#<.*>$/
        end
      end

      new_hash
    end
    
    def self.reduce_hash_size(hash)
      new_hash = {}

      hash.each do |k,v|
        if v.is_a?(Hash)
          new_hash[k] = reduce_hash_size(v)
        else
          new_hash[k] = v.to_s.slice(0, MAX_STRING_LENGTH)
        end
      end

      new_hash
    end

    # Helper functions to work around MultiJson changes in 1.3+
    def self.dump_json(object, options={})
      if MultiJson.respond_to?(:adapter)
        MultiJson.dump(object, options)
      else
        MultiJson.encode(object, options)
      end
    end

    def self.load_json(json, options={})
      if MultiJson.respond_to?(:adapter)
        MultiJson.load(json, options)
      else
        MultiJson.decode(json, options)
      end
    end
  end
end