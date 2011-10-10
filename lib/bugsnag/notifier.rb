require "httparty"
require "multi_json"

module Bugsnag
  class Notifier
    include HTTParty

    headers  "Content-Type" => "application/json"
    
    NOTIFIER_NAME = "Ruby Bugsnag Notifier"
    NOTIFIER_VERSION = "1.0.0"
    NOTIFIER_URL = "http://www.bugsnag.com"

    def initialize(configuration)
      @configuration = configuration
    end

    def notify(exception, meta_data={})
      Bugsnag.log("Notifying #{@configuration.endpoint} of exception")

      event = Bugsnag::Event.new(exception, "TODO USER ID", {
        :app_environment => build_app_environment,
        :web_environment => build_web_environment,
        :meta_data => meta_data
      })
      
      payload = {
        :apiKey => @configuration.api_key,
        :notifier => {
          :name => NOTIFIER_NAME,
          :version => NOTIFIER_VERSION,
          :url => NOTIFIER_URL
        },
        :errors => [event.as_hash]
      }

      self.class.post(@configuration.endpoint, {:body => MultiJson.encode(payload)})
      
      Bugsnag.log("Notified #{@configuration.endpoint} of exception")
    end
    
    private
    def build_app_environment
      {
        :releaseStage => @configuration.release_stage,
        :projectRoot => @configuration.project_root.to_s
        # TODO: Add in environmental variables
      }
    end
    
    def build_web_environment
      {
        
      }
    end
  end
end