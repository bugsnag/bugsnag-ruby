require "httparty"
require "multi_json"

namespace :bugsnag do
  desc "Notify Bugsnag of a new deploy."
  task :deploy => :environment do
    # Build the deploy payload
    payload = {
      :apiKey => ENV["BUGSNAG_API_KEY"] || Bugsnag.configuration.api_key,
      :releaseStage => ENV["BUGSNAG_RELEASE_STAGE"] || ENV["RAILS_ENV"] || ENV["RACK_ENV"] || Bugsnag.configuration.release_stage
    }
    payload[:appVersion] = ENV["BUGSNAG_APP_VERSION"] if ENV["BUGSNAG_APP_VERSION"]
    payload[:repository] = ENV["BUGSNAG_REPOSITORY"] if ENV["BUGSNAG_REPOSITORY"]

    # Post the deploy notification
    begin
      endpoint = (Bugsnag.configuration.use_ssl ? "https://" : "http://") \
               + (Bugsnag.configuration.endpoint || Bugsnag::Notification::DEFAULT_ENDPOINT) \
               + "/deploy"

      HTTParty.post(endpoint, {
        :body => MultiJson.dump(payload),
        :headers => {"Content-Type" => "application/json"}
      })
    rescue Exception => e
      Bugsnag.log("Deploy notification failed, #{e.inspect}")
    end
  end

  desc "Send a test exception to Bugsnag."
  task :test_exception => :environment do 
    begin
      raise RuntimeError.new("Bugsnag test exception")
    rescue => e
      Bugsnag.notify(e, {:context => "rake#test_exception"})
    end
  end
end