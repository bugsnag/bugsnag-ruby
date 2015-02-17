require 'uri'

module Bugsnag
  module Helpers
    MAX_STRING_LENGTH = 4096

    def self.cleanup_obj(obj, filters = nil, seen=Set.new)
      return nil unless obj

      # Protect against recursion of recursable items
      if obj.is_a?(Hash) || obj.is_a?(Array) || obj.is_a?(Set)
        return "[RECURSION]" if seen.include? obj

        # We duplicate the seen set here so that no updates by further cleanup_obj calls
        # are persisted beyond that call.
        seen = seen.dup
        seen << obj
      end

      case obj
      when Hash
        clean_hash = {}
        obj.each do |k,v|
          if filters_match?(k, filters)
            clean_hash[k] = "[FILTERED]"
          else
            clean_obj = cleanup_obj(v, filters, seen)
            clean_hash[k] = clean_obj
          end
        end
        clean_hash
      when Array, Set
        obj.map { |el| cleanup_obj(el, filters, seen) }.compact
      when Numeric, TrueClass, FalseClass
        obj
      when String
        cleanup_string(obj)
      else
        str = obj.to_s
        # avoid leaking potentially sensitive data from objects' #inspect output
        if str =~ /#<.*>/
          '[OBJECT]'
        else
          str
        end
      end
    end

    def self.cleanup_string(str)
      if defined?(str.encoding) && defined?(Encoding::UTF_8)
        if str.encoding == Encoding::UTF_8
          str.valid_encoding? ? str : str.encode('utf-16', {:invalid => :replace, :undef => :replace}).encode('utf-8')
        else
          str.encode('utf-8', {:invalid => :replace, :undef => :replace})
        end
      elsif defined?(Iconv)
        Iconv.conv('UTF-8//IGNORE', 'UTF-8', str) || str
      else
        str
      end
    end

    def self.cleanup_obj_encoding(obj)
      cleanup_obj(obj, nil)
    end

    def self.filters_match?(object, filters)
      str = object.to_s

      Array(filters).any? do |f|
        case f
        when Regexp
          str.match(f)
        else
          str.include?(f.to_s)
        end
      end
    end

    def self.cleanup_url(url, filters = [])
      return url if filters.empty?

      uri = URI(url)
      return url unless uri.query

      query_params = uri.query.split('&').map { |pair| pair.split('=') }
      query_params.map! do |key, val|
        if filters_match?(key, filters)
          "#{key}=[FILTERED]"
        else
          "#{key}=#{val}"
        end
      end

      uri.query = query_params.join('&')
      uri.to_s
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
