require "json"

module Bugsnag
  class Deploy
    def self.notify(opts = {})

      configuration = Bugsnag.configuration.dup

      # update configuration based on parameters passed in
      [:api_key, :app_version, :release_stage, :endpoint, :use_ssl,
       :proxy_host, :proxy_port, :proxy_user, :proxy_password].each do |param|
        unless opts[param].nil?
          configuration.send :"#{param}=", opts[param]
        end
      end

      endpoint = (configuration.use_ssl ? "https://" : "http://") + configuration.endpoint + "/deploy"

      parameters = {
        "apiKey" => configuration.api_key,
        "releaseStage" => configuration.release_stage,
        "appVersion" => configuration.app_version,
        "revision" => opts[:revision],
        "repository" => opts[:repository],
        "branch" => opts[:branch]
      }.reject {|k,v| v == nil}

      raise RuntimeError.new("No API key found when notifying of deploy") if !parameters["apiKey"] || parameters["apiKey"].empty?

      payload_string = ::JSON.dump(parameters)
      Bugsnag::Delivery::Synchronous.deliver(endpoint, payload_string, configuration)
    end
  end
end
