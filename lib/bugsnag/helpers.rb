module HTTParty
  class Parser
    def json
      MultiJson.decode(body)
    end
  end
end

module Bugsnag
  module Helpers
    MAX_STRING_LENGTH = 1024

    def self.cleanup_hash(hash, filters=nil)
      hash.each do |k,v|
        if filters && filters.any? {|f| k.to_s.include?(f.to_s)}
          hash[k] = "[FILTERED]"
        elsif v.is_a?(Hash)
          cleanup_hash(v, filters)
        else
          hash[k] = v.to_s.slice(0, MAX_STRING_LENGTH)
        end
      end
    end

    def self.param_context(params)
      "#{params[:controller]}##{params[:action]}" if params && params[:controller] && params[:action]
    end

    def self.request_context(request)
      "#{request.request_method} #{request.path}" if request
    end
  end
end