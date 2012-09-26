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

    def self.cleanup_obj(obj, filters = nil)
      if obj.is_a?(Hash)
        obj.inject({}) do |h, (k,v)| 
          if filters && filters.any? {|f| k.to_s.include?(f.to_s)}
            h[k] = "[FILTERED]"
          else
            h[k] = cleanup_obj(v, filters)
          end
          h
        end
      elsif obj.is_a?(Array) || obj.is_a?(Set)
        obj.map { |el| cleanup_obj(el, filters) }
      else
        obj.to_s
      end
    end
    
    def self.reduce_hash_size(hash)
      hash.inject({}) do |h, (k,v)|
        if v.is_a?(Hash)
          h[k] = reduce_hash_size(v)
        else
          h[k] = v.to_s.slice(0, MAX_STRING_LENGTH)
        end

        h
      end
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