require "bugsnag"
require "httparty"
require "multi_json"
require "net/http"
require "uri"

namespace :bugsnag do
  desc "Notify Bugsnag of a new deploy."
  task :deploy do
    # Post the deploy notification
    begin
      require 'bugsnag'

      release_stage = ENV["BUGSNAG_RELEASE_STAGE"] || "production"
      app_version = ENV["BUGSNAG_APP_VERSION"]
      revision = ENV["BUGSNAG_REVISION"]
      repository = ENV["BUGSNAG_REPOSITORY"]
      branch = ENV["BUGSNAG_BRANCH"]

      raise RuntimeError.new("No API key found when notifying deploy") unless bugsnag.ensure_configured

      endpoint = (Bugsnag.configuration.use_ssl ? "https://" : "http://") \
                 + (Bugsnag.configuration.endpoint || Bugsnag::Notification::DEFAULT_ENDPOINT) \
                 + "/deploy"
      uri = URI.parse(endpoint)

      parameters = {
        "apiKey" => Bugsnag.configuration.api_key,
        "releaseStage" => release_stage,
        "appVersion" => app_version,
        "revision" => revision,
        "repository" => repository,
        "branch" => branch
      }

      Net::HTTP.post_form(uri, parameters)

    rescue Exception => e
      Bugsnag.warn("Deploy notification failed, #{e.inspect}")
    end
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
end

task :load do
  begin 
    Rake::Task["environment"].invoke
  rescue
  end
end
