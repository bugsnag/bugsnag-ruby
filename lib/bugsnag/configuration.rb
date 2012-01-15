module Bugsnag
  class Configuration
    attr_accessor :api_key, :release_stage, :project_root, :app_version, :framework, :endpoint, :logger, :disable_auto_notification
  end
end