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
require "bugsnag/notification"

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

    def notify(exception, session_data={})
      # Optionally provide session_data when you have it
      # session_data = {
      #   :userId => "...",
      #   :context => "...",
      #   :metadata => {
      #     :environment => {},
      #     :session => {},
      #     :params => {}
      #   }
      # }

      opts = {
        :releaseStage => configuration.release_stage,
        :projectRoot => configuration.project_root,
        :appVersion => configuration.app_version
      }.merge(session_data)

      # Send the notification
      notification = Notification.new(configuration.api_key, exception, opts)
      notification.send
    end

    def log(message)
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