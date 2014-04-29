require "net/http"
require "uri"
require "bugsnag"

module Bugsnag
  class Deploy
    def self.notify(opts = {})
      opts[:api_key] ||= Bugsnag.configuration.api_key
      opts[:release_stage] ||= "production"
      opts[:endpoint] ||= Bugsnag.configuration.endpoint
      opts[:use_ssl] = Bugsnag.configuration.use_ssl if opts[:use_ssl] == nil
      opts[:proxy_host] ||= Bugsnag.configuration.proxy_host
      opts[:proxy_port] ||= Bugsnag.configuration.proxy_port
      opts[:proxy_user] ||= Bugsnag.configuration.proxy_user
      opts[:proxy_password] ||= Bugsnag.configuration.proxy_password

      endpoint = (opts[:use_ssl] ? "https://" : "http://") + opts[:endpoint] + "/deploy"

      parameters = {
        "apiKey" => opts[:api_key],
        "releaseStage" => opts[:release_stage],
        "appVersion" => opts[:app_version],
        "revision" => opts[:revision],
        "repository" => opts[:repository],
        "branch" => opts[:branch]
      }.reject {|k,v| v == nil}

      raise RuntimeError.new("No API key found when notifying of deploy") if !parameters["apiKey"] || parameters["apiKey"].empty?

      uri = URI.parse(endpoint)
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data(parameters)
      http = Net::HTTP.new(
        uri.host,
        uri.port,
        opts[:proxy_host],
        opts[:proxy_port],
        opts[:proxy_user],
        opts[:proxy_password]
      )
      http.use_ssl = true if opts[:use_ssl]
      http.request(req)
    end
  end
end
