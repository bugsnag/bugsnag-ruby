module Bugsnag
  class Configuration
    OPTIONS = [
      :api_key, :release_stage, :project_root, :app_version,
      :framework, :endpoint, :logger, :disable_auto_notification,
      :params_filters, :stacktrace_filters, :ignore_classes,
      :use_resque
    ]
    OPTIONS.each {|o| attr_accessor o }


    DEFAULT_ENDPOINT = "http://api.bugsnag.com/notify"
    DEFAULT_PARAMS_FILTERS = %w(password password_confirmation).freeze

    DEFAULT_STACKTRACE_FILTERS = [
      lambda { |line|
        if defined?(Bugsnag.configuration.project_root) && Bugsnag.configuration.project_root.to_s != '' 
          line.sub(/#{Bugsnag.configuration.project_root}\//, "")
        else
          line
        end
      },
      lambda { |line| line.gsub(/^\.\//, "") },
      lambda { |line|
        if defined?(Gem)
          Gem.path.inject(line) do |line, path|
            line.gsub(/#{path}\//, "")
          end
        end
      },
      lambda { |line| line if line !~ %r{lib/bugsnag} }
    ].freeze

    DEFAULT_IGNORE_CLASSES = [
      "ActiveRecord::RecordNotFound",
      "ActionController::RoutingError",
      "ActionController::InvalidAuthenticityToken",
      "CGI::Session::CookieStore::TamperedWithCookie",
      "ActionController::UnknownAction",
      "AbstractController::ActionNotFound"
    ]


    def initialize
      @endpoint = DEFAULT_ENDPOINT
      @params_filters = DEFAULT_PARAMS_FILTERS.dup
      @stacktrace_filters = DEFAULT_STACKTRACE_FILTERS.dup
      @ignore_classes = DEFAULT_IGNORE_CLASSES.dup
    end
    
    def to_hash
      OPTIONS.inject({}) do |hash, option|
        hash.merge(option.to_sym => send(option))
      end
    end

    def merge(hash)
      to_hash.merge(hash)
    end
  end
end