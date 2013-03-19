require "bugsnag"
require "httparty"
require "multi_json"

namespace :bugsnag do
  desc "Notify Bugsnag of a new deploy."
  task :deploy do
    # Post the deploy notification
    begin
      require 'bugsnag'

      api_key = ENV["BUGSNAG_API_KEY"]
      releaseStage = ENV["BUGSNAG_RELEASE_STAGE"] || "production"
      appVersion = ENV["BUGSNAG_APP_VERSION"]
      revision = ENV["BUGSNAG_REVISION"]
      repository = ENV["BUGSNAG_REPOSITORY"]
      branch = ENV["BUGSNAG_BRANCH"]

      begin
        require './config/initializers/bugsnag'
      rescue Exception => e
        config = YAML.load_file("./config/bugsnag.yml") if File.exists?("./config/bugsnag.yml")
        Bugsnag.configure(config[releaseStage] ? config[releaseStage] : config) if config
      end

      # Fetch and check the api key
      api_key ||= Bugsnag.configuration.api_key
      raise RuntimeError.new("No API key found when notifying deploy") if !api_key || api_key.empty?

      endpoint = (Bugsnag.configuration.use_ssl ? "https://" : "http://") \
                 + (Bugsnag.configuration.endpoint || Bugsnag::Notification::DEFAULT_ENDPOINT) \
                 + "/deploy"

      parameters = {
        "apiKey" => api_key,
        "releaseStage" => releaseStage,
        "appVersion" => appVersion,
        "revision" => revision,
        "repository" => repository,
        "branch" => branch
      }

      query = parameters.delete_if {|k,v| v.nil? }.map { |k,v| "#{k}=#{v}" }.join("&")

      `curl -d \"#{query}\" #{endpoint} 2&>1 /dev/null`

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
