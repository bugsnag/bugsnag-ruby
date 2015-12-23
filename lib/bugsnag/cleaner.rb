require 'uri'

module Bugsnag
  class Cleaner
    ENCODING_OPTIONS = {:invalid => :replace, :undef => :replace}.freeze
    FILTERED = '[FILTERED]'.freeze
    RECURSION = '[RECURSION]'.freeze
    OBJECT = '[OBJECT]'.freeze

    def initialize(filters)
      @filters = Array(filters)
      @deep_filters = @filters.any? {|f| f.kind_of?(Regexp) && f.to_s.include?("\\.".freeze) }
    end

    def clean_object(obj)
      traverse_object(obj, {}, nil)
    end

    def traverse_object(obj, seen, scope)
      return nil unless obj

      # Protect against recursion of recursable items
      protection = if obj.is_a?(Hash) || obj.is_a?(Array) || obj.is_a?(Set)
        return seen[obj] if seen[obj]
        seen[obj] = RECURSION
      end

      value = case obj
      when Hash
        clean_hash = {}
        obj.each do |k,v|
          if filters_match_deeply?(k, scope)
            clean_hash[k] = FILTERED
          else
            clean_hash[k] = traverse_object(v, seen, [scope, k].compact.join('.'))
          end
        end
        clean_hash
      when Array, Set
        obj.map { |el| traverse_object(el, seen, scope) }.compact
      when Numeric, TrueClass, FalseClass
        obj
      when String
        clean_string(obj)
      else
        str = obj.to_s
        # avoid leaking potentially sensitive data from objects' #inspect output
        if str =~ /#<.*>/
          OBJECT
        else
          clean_string(str)
        end
      end

      seen[obj] = value if protection
      value
    end

    def clean_string(str)
      if defined?(str.encoding) && defined?(Encoding::UTF_8)
        if str.encoding == Encoding::UTF_8
          str.valid_encoding? ? str : str.encode('utf-16', ENCODING_OPTIONS).encode('utf-8')
        else
          str.encode('utf-8', ENCODING_OPTIONS)
        end
      elsif defined?(Iconv)
        Iconv.conv('UTF-8//IGNORE', 'UTF-8', str) || str
      else
        str
      end
    end

    def self.clean_object_encoding(obj)
      new(nil).clean_object(obj)
    end

    def clean_url(url)
      return url if @filters.empty?

      uri = URI(url)
      return url unless uri.query

      query_params = uri.query.split('&').map { |pair| pair.split('=') }
      query_params.map! do |key, val|
        if filters_match?(key)
          "#{key}=#{FILTERED}"
        else
          "#{key}=#{val}"
        end
      end

      uri.query = query_params.join('&')
      uri.to_s
    end

    private

    def filters_match?(key)
      str = key.to_s

      @filters.any? do |f|
        case f
        when Regexp
          str.match(f)
        else
          str.include?(f.to_s)
        end
      end
    end

    # If someone has a Rails filter like /^stuff\.secret/, it won't match "request.params.stuff.secret",
    # so we try it both with and without the "request.params." bit.
    def filters_match_deeply?(key, scope)
      return true if filters_match?(key)
      return false unless @deep_filters

      long = [scope, key].compact.join('.')
      short = long.sub(/^request\.params\./, '')
      filters_match?(long) || filters_match?(short)
    end
  end
end
