require "rubygems"

# begin
#   require "active_support"
#   require "active_support/core_ext"
# rescue LoadError
#   require "activesupport"
#   require "activesupport/core_ext"
# end

require "bugsnag/version"
require "bugsnag/configuration"
require "bugsnag/event"
require "bugsnag/notifier"

require "bugsnag/rack"
require "bugsnag/railtie" if defined?(Rails::Railtie)

module Bugsnag
  LOG_PREFIX = "** [Bugsnag] "

  class << self
    attr_accessor :notifier

    def configure
      yield(configuration)
      self.notifier = Notifier.new(configuration)
      
      log "Bugsnag exception handler #{VERSION} ready, api_key=#{configuration.api_key}" if configuration.api_key
    end

    def notify(exception, options={})
      notifier.notify(exception, options)
    end

    def log(message)      
      puts "BUGSNAG: #{message}"
      logger.info(LOG_PREFIX + message) if logger
    end

    def configuration
      @configuration ||= Bugsnag::Configuration.new
    end

    private
    def logger
      configuration.logger
    end
  end
end