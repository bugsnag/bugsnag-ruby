require "net/http"
require "uri"

module Bugsnag
  class Deploy
    def self.notify(opts = {})
      opts[:api_key] ||= Bugsnag.configuration.api_key
      opts[:release_stage] ||= "production"
      opts[:endpoint] ||= Bugsnag.configuration.endpoint
      opts[:use_ssl] = Bugsnag.configuration.use_ssl if opts[:use_ssl] == nil

      endpoint = (opts[:use_ssl] ? "https://" : "http://") + opts[:endpoint] + "/deploy"

      parameters = {
        "apiKey" => opts[:api_key],
        "releaseStage" => opts[:release_stage],
        "appVersion" => opts[:app_version],
        "revision" => opts[:revision],
        "repository" => opts[:repository],
        "branch" => opts[:branch]
      }.reject {|k,v| v == nil}

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
    rescue Exception => e
      Bugsnag.warn("Deploy notification failed, #{e.inspect}")
    end
  end
end