require "bugsnag"

namespace :bugsnag do
  desc "Notify Bugsnag of a new deploy."
  task :deploy do
    api_key = ENV["BUGSNAG_API_KEY"]
    release_stage = ENV["BUGSNAG_RELEASE_STAGE"]
    app_version = ENV["BUGSNAG_APP_VERSION"]
    revision = ENV["BUGSNAG_REVISION"]
    repository = ENV["BUGSNAG_REPOSITORY"]
    branch = ENV["BUGSNAG_BRANCH"]

    Rake::Task["load"].invoke unless api_key

    Bugsnag::Deploy.notify({
      :api_key => api_key,
      :release_stage => release_stage,
      :app_version => app_version,
      :revision => revision,
      :repository => repository,
      :branch => branch
    })
  end

  desc "Send a test exception to Bugsnag."
  task :test_exception => :load do
    begin
      raise RuntimeError.new("Bugsnag test exception")
    rescue => e
      Bugsnag.notify(e, {:context => "rake#test_exception"})
    end
  end

  desc "Show the bugsnag middleware stack"
  task :middleware => :load do
    Bugsnag.configuration.middleware.each {|m| puts m.to_s}
  end

  namespace :heroku do
    desc "Add a heroku deploy hook to notify Bugsnag of deploys"
    task :add_deploy_hook => :load do
      # Wrapper to run command safely even in bundler
      run_command = lambda { |command|
        defined?(Bundler.with_clean_env) ? Bundler.with_clean_env { `#{command}` } : `#{command}`
      }

      # Fetch heroku config settings
      config_command = "heroku config --shell"
      config_command += " --app #{ENV["HEROKU_APP"]}" if ENV["HEROKU_APP"]
      heroku_env = run_command.call(config_command).split(/[\n\r]/).each_with_object({}) do |c, obj|
        k,v = c.split("=")
        obj[k] = (v.nil? || v.strip.empty?) ? nil : v
      end

      # Check for Bugsnag API key (required)
      api_key = heroku_env["BUGSNAG_API_KEY"] || Bugsnag.configuration.api_key || ENV["BUGSNAG_API_KEY"]
      unless api_key
        puts "Error: No API key found, have you run 'heroku config:set BUGSNAG_API_KEY=your-api-key'?"
        next
      end

      # Build the request, making use of deploy hook variables
      # (https://devcenter.heroku.com/articles/deploy-hooks#customizing-messages)
      params = {
        :apiKey => api_key,
        :branch => "master",
        :revision => "{{head_long}}",
        :releaseStage => heroku_env["RAILS_ENV"] || ENV["RAILS_ENV"] || "production"
      }
      repo = `git config --get remote.origin.url`.strip
      params[:repository] = repo unless repo.empty?

      # Add the hook
      url = "https://notify.bugsnag.com/deploy?" + params.map {|k,v| "#{k}=#{v}"}.join("&")
      command = "heroku addons:add deployhooks:http --url=\"#{url}\""
      command += " --app #{ENV["HEROKU_APP"]}" if ENV["HEROKU_APP"]

      puts "$ #{command}"
      run_command.call(command)
    end
  end
end

task :load do
  begin
    Rake::Task["environment"].invoke
  rescue
  end
end
