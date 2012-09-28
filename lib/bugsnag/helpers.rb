module HTTParty
  class Parser
    def json
      Bugsnag::Helpers.load_json(body)
    end
  end
end

module Bugsnag
  module Helpers
    MAX_STRING_LENGTH = 4096

    def self.cleanup_obj(obj, filters = nil)
      return nil unless obj

      if obj.is_a?(Hash)
        clean_hash = {}
        obj.each do |k,v| 
          if filters && filters.any? {|f| k.to_s.include?(f.to_s)}
            clean_hash[k] = "[FILTERED]"
          else
            clean_obj = cleanup_obj(v, filters)
            clean_hash[k] = clean_obj unless clean_obj.nil?
          end
        end
        clean_hash
      elsif obj.is_a?(Array) || obj.is_a?(Set)
        obj.map { |el| cleanup_obj(el, filters) }.compact
      elsif obj.is_a?(Integer) || obj.is_a?(Float)
        obj
      else
        obj.to_s unless obj.to_s =~ /#<.*>/
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