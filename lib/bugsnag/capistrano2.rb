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
            Bugsnag::Deploy.notify({
              :api_key => fetch(:bugsnag_api_key, nil),
              :release_stage => fetch(:rails_env, "production"),
              :revision => fetch(:current_revision, nil),
              :repository => fetch(:repository, nil),
              :branch => fetch(:branch, nil)
            })

            logger.info "Bugsnag deploy notification complete."
          end
        end
      end
    end
  end
end

Bugsnag::Capistrano.load_into(Capistrano::Configuration.instance) if Capistrano::Configuration.instance

