require "bugsnag"
require "httparty"
require "multi_json"

namespace :bugsnag do
  desc "Notify Bugsnag of a new deploy."
  task :deploy => :load do
    # Fetch and check the api key
    api_key = ENV["BUGSNAG_API_KEY"] || Bugsnag.configuration.api_key
    raise RuntimeError.new("No API key found when notifying deploy") if !api_key || api_key.empty?

    # Build the deploy payload
    payload = {
      :apiKey => api_key,
      :releaseStage => ENV["BUGSNAG_RELEASE_STAGE"] || Bugsnag.configuration.release_stage
    }
    payload[:appVersion] = ENV["BUGSNAG_APP_VERSION"] if ENV["BUGSNAG_APP_VERSION"]
    payload[:revision] = ENV["BUGSNAG_REVISION"] if ENV["BUGSNAG_REVISION"]
    payload[:repository] = ENV["BUGSNAG_REPOSITORY"] if ENV["BUGSNAG_REPOSITORY"]
    payload[:branch] = ENV["BUGSNAG_BRANCH"] if ENV["BUGSNAG_BRANCH"]

    # Post the deploy notification
    begin
      endpoint = (Bugsnag.configuration.use_ssl ? "https://" : "http://") \
               + (Bugsnag.configuration.endpoint || Bugsnag::Notification::DEFAULT_ENDPOINT) \
               + "/deploy"

      HTTParty.post(endpoint, {
        :body => Bugsnag::Helpers.dump_json(payload),
        :headers => {"Content-Type" => "application/json"}
      })
    rescue Exception => e
      Bugsnag.log("Deploy notification failed, #{e.inspect}")
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
