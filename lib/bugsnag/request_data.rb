module Bugsnag
  class RequestData
    THREAD_LOCAL_NAME = "bugsnag_req_data"

    attr_accessor :request_data
    
    def initialize
      # Set up the defaults
      self.request_data = {}
    end
    
    def set_request_data(key, value)
      Bugsnag.warn "Overwriting request data for key #{key.to_s}" if self.request_data[key]
      self.request_data[key] = value
    end
    
    def unset_request_data(key, value)
      self.request_data.delete(key)
    end

    def self.get_instance
      Thread.current[THREAD_LOCAL_NAME] ||= Bugsnag::RequestData.new
    end
    
    def self.clear_instance
      Thread.current[THREAD_LOCAL_NAME] = nil
    end
  end
end