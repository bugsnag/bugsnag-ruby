module Bugsnag::Breadcrumbs

  class Breadcrumb
    attr_accessor :message
    attr_accessor :type
    attr_accessor :meta_data
    attr_reader :auto
    attr_reader :timestamp

    def initialize(message, type, meta_data, auto)
      @should_ignore = false
      self.message = message
      self.type = type
      self.meta_data = meta_data
      @auto = auto
      @timestamp = Time.now().utc().strftime('%Y-%m-%dT%H:%M:%S')
    end

    def ignore!
      @should_ignore = true
    end

    def ignore?
      @should_ignore
    end

    def to_h
      {
        :message => message,
        :type => type,
        :metaData => meta_data,
        :timestamp => timestamp
      }
    end
  end
end