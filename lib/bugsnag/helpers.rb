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

    def self.cleanup_obj(obj, filters = nil, seen=Set.new)
      return nil unless obj

      # Protect against recursion of recursable items
      if obj.is_a?(Hash) || obj.is_a?(Array) || obj.is_a?(Set)
        return "[RECURSION]" if seen.include? obj
        seen << obj

        # We duplicate the seen set here so that no updates by further cleanup_obj calls
        # are persisted beyond that call.
        seen = seen.dup
      end

      if obj.is_a?(Hash)
        clean_hash = {}
        obj.each do |k,v| 
          if filters && filters.any? {|f| k.to_s.include?(f.to_s)}
            clean_hash[k] = "[FILTERED]"
          else
            clean_obj = cleanup_obj(v, filters, seen)
            clean_hash[k] = clean_obj
          end
        end
        clean_hash
      elsif obj.is_a?(Array) || obj.is_a?(Set)
        obj.map { |el| cleanup_obj(el, filters, seen) }.compact
      elsif obj.is_a?(Integer) || obj.is_a?(Float) || obj.is_a?(String)
        obj
      else
        obj.to_s unless obj.to_s =~ /#<.*>/
      end
    end

    def self.cleanup_url(url, filters = nil)
      return url unless filters

      filter_regex = Regexp.new("([?&](?:[^&=]*#{filters.to_a.join('|[^&=]*')}[^&=]*)=)[^&]*")
      
      url.gsub(filter_regex, '\1[FILTERED]')
    end
    
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
