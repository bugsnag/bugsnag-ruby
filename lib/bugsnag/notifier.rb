require "httparty"
require "multi_json"

module Bugsnag
  class Notifier
    include HTTParty

    headers  "Content-Type" => "application/json"
    
    NOTIFIER_NAME = "Ruby Bugsnag Notifier"
    NOTIFIER_VERSION = Bugsnag::VERSION
    NOTIFIER_URL = "http://www.bugsnag.com"

    def initialize(configuration)
      @configuration = configuration
    end

    def notify(exception, options={})
      Bugsnag.log("Notifying #{@configuration.endpoint} of exception")

      event = Bugsnag::Event.new(exception, @configuration.user_id, @configuration.project_root, {
        :app_environment => build_app_environment,
        :web_environment => options[:request_data],
        :meta_data => options[:meta_data]
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

      begin
        response = self.class.post(@configuration.endpoint, {:body => MultiJson.encode(payload)})
      rescue Exception => e
        Bugsnag.log("Notification to #{@configuration.endpoint} failed, #{e.inspect}")
      end
      
      return response
    end
    
    private
    def build_app_environment
      {
        :releaseStage => @configuration.release_stage,
        :projectRoot => @configuration.project_root.to_s
        # TODO: Add in environmental variables?
      }
    end
  end
end