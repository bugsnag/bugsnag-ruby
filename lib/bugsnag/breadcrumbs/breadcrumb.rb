module Bugsnag::Breadcrumbs
  class Breadcrumb
    attr_accessor :message
    attr_accessor :type
    attr_accessor :meta_data
    attr_reader :auto
    attr_reader :timestamp

    ##
    # Creates a breadcrumb.
    #
    # This will not have been validated, which must occur before this is
    # attached to a report.
    def initialize(message, type, meta_data, auto)
      @should_ignore = false
      self.message = message
      self.type = type
      self.meta_data = meta_data

      # Use the symbol comparison to improve readability of breadcrumb creation
      @auto = auto == :auto

      # Store it as a timestamp for now
      @timestamp = Time.now
    end

    ##
    # Flags the breadcrumb to be ignored.
    #
    # Ignored breadcrumbs will not be attached to a report.
    def ignore!
      @should_ignore = true
    end

    ##
    # Checks if the `ignore!` method has been called.
    #
    # Ignored breadcrumbs will not be attached to a report.
    def ignore?
      @should_ignore
    end

    ##
    # Outputs the breadcrumb data in a formatted hash.
    #
    # These adhere to the breadcrumb format as defined in the Bugsnag error 
    # reporting API
    def to_h
      {
        :name => @message,
        :type => @type,
        :metaData => @meta_data,
        :timestamp => @timestamp.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
      }
    end
  end
end
