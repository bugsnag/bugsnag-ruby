require "httparty"
require "multi_json"

module Bugsnag
  module Capistrano
    ALLOWED_ENV_SETTINGS = %w{BUGSNAG_RELEASE_STAGE BUGSNAG_REPOSITORY BUGSNAG_REVISION BUGSNAG_BRANCH BUGSNAG_API_KEY BUGSNAG_APP_VERSION}

    def self.load_into(configuration)
      configuration.load do
        after "deploy",            "bugsnag:deploy"
        after "deploy:migrations", "bugsnag:deploy"

        namespace :bugsnag do
          desc "Notify Bugsnag that new production code has been deployed"
          task :deploy, :except => { :no_release => true }, :on_error => :continue do
            # Build the rake command
            rake         = fetch(:rake, "rake")
            rails_env    = fetch(:rails_env, "production")
            bugsnag_env  = fetch(:bugsnag_env, rails_env)
            rake_command = "cd '#{current_path}' && RAILS_ENV=#{rails_env} #{rake} bugsnag:deploy"

            # Build the new environment to pass through to rake
            new_env = {
              "BUGSNAG_RELEASE_STAGE" => bugsnag_env,
              "BUGSNAG_REVISION"      => fetch(:current_revision, nil),
              "BUGSNAG_REPOSITORY"    => fetch(:repository, nil),
              "BUGSNAG_BRANCH"        => fetch(:branch, nil),
              "BUGSNAG_API_KEY"       => fetch(:bugsnag_api_key, nil)
            }.reject { |_, v| v.nil? }

            # Pass through any existing env variables
            ALLOWED_ENV_SETTINGS.each { |opt| new_env[opt] = ENV[opt] if ENV[opt] }

            # Append the env to the rake command
            rake_command << " #{new_env.map{|k,v| "#{k}=#{v}"}.join(" ")}"

            # Run the rake command (only on one server)
            run(rake_command, :once => true)
            
            logger.info "Bugsnag deploy notification complete."
          end
        end
      end
    end
  end
end

Bugsnag::Capistrano.load_into(Capistrano::Configuration.instance) if Capistrano::Configuration.instance

