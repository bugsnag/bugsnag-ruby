require "rubygems"

# begin
#   require "active_support"
#   require "active_support/core_ext"
# rescue LoadError
#   require "activesupport"
#   require "activesupport/core_ext"
# end

require "bugsnag/configuration"
require "bugsnag/event"
require "bugsnag/notifier"
require "bugsnag/version"

require "bugsnag/rack"
require "bugsnag/railtie" if defined?(Rails::Railtie)

module Bugsnag
  LOG_PREFIX = "** [Bugsnag] "

  class << self
    attr_accessor :notifier

    def configure
      yield(configuration)
      self.notifier = Notifier.new(configuration)
      
      log "Bugsnag exception handler #{VERSION} ready, #{configuration.to_hash.inspect}"
    end

    def notify(exception)
      notifier.notify(exception)
    end

    def log(message)
      logger.info(LOG_PREFIX + message) if logger
    end

    private
    def configuration
      @configuration ||= Bugsnag::Configuration.new
    end
    
    def logger
      configuration.logger
    end
  end
end