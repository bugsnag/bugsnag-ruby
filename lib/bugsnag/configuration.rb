module Bugsnag
  class Configuration
    @@options = :api_key, :release_stage, :project_root, :app_version, :endpoint, :logger, :disable_auto_notification
    @@options.each do |attribute|
      attr_accessor attribute
    end
  end
end