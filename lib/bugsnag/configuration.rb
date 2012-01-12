module Bugsnag
  class Configuration
    @@options = :api_key, :release_stage, :endpoint, :user_id, :project_root, :logger, :disable_auto_notification
    @@options.each do |attribute|
      attr_accessor attribute
    end

    def initialize
      @endpoint = "http://api.bugsnag.com/notify"
    end

    def to_hash
      @@options.inject({}) do |hash, option|
        hash.merge(option.to_sym => send(option))
      end
    end
  end
end