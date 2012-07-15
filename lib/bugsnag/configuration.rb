module Bugsnag
  class Configuration
    OPTIONS = [
      :api_key, :release_stage, :notify_release_stages, :auto_notify,
      :use_ssl, :project_root, :app_version,
      :params_filters, :ignore_classes,
      
      :stacktrace_filters,
      :framework, :endpoint, :logger,
      :delay_with_resque
    ]
    OPTIONS.each {|o| attr_accessor o }

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
      "AbstractController::ActionNotFound",
      "Mongoid::Errors::DocumentNotFound"
    ]


    def initialize
      @params_filters = DEFAULT_PARAMS_FILTERS.dup
      @stacktrace_filters = DEFAULT_STACKTRACE_FILTERS.dup
      @ignore_classes = DEFAULT_IGNORE_CLASSES.dup
      @auto_notify = true
      @release_stage = "production"
      @notify_release_stages = ["production"]
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