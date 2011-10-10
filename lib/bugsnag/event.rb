require "multi_json"

module Bugsnag
  class Event
    attr_accessor :exception, :user_id, :project_root, :app_environment, :web_environment, :meta_data
    
    def initialize(exception, user_id, project_root, env={})
      self.exception = exception
      self.user_id = user_id
      self.project_root = project_root
      self.app_environment = env[:app_environment]
      self.web_environment = env[:web_environment]
      self.meta_data = env[:meta_data]
    end

    def error_class
      exception.class.to_s
    end
    
    def message
      exception.message
    end

    def stacktrace
      return @stacktrace if @stacktrace

      if exception.backtrace
        @stacktrace = exception.backtrace.map do |trace|
          method = nil
          file, line_str, method_str = trace.split(":")
        
          trace_hash = {
            :file => file,
            :lineNumber => line_str.to_i
          }
        
          if method_str
            method_match = /in `([^']+)'/.match(method_str)
            method = method_match.captures.first if method_match
          end

          trace_hash[:method] = method if method
          trace_hash[:inProject] = true if project_root && file.match(/^#{project_root}/)
        
          trace_hash
        end
      else
        @stacktrace = []
      end
      
      @stacktrace
    end

    def as_hash
      {
        :userId => user_id,
        :causes => [{
          :errorClass => error_class,
          :message => message,
          :stacktrace => stacktrace
        }],
        :appEnvironment => app_environment,
        :webEnvironment => web_environment,
        :metaData => meta_data
      }
    end

    def as_json
      MultiJson.encode(as_hash)
    end
  end
end