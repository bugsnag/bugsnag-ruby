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

      api_key = ENV["BUGSNAG_API_KEY"]
      releaseStage = ENV["BUGSNAG_RELEASE_STAGE"] || "production"
      appVersion = ENV["BUGSNAG_APP_VERSION"]
      revision = ENV["BUGSNAG_REVISION"]
      repository = ENV["BUGSNAG_REPOSITORY"]
      branch = ENV["BUGSNAG_BRANCH"]

      begin
        require Rails.root.join('config/initializers/bugsnag')
      rescue Exception => e
        yml_filename = Rails.root.join("config","bugsnag.yml")
        config = YAML.load_file(yml_filename) if File.exists?(yml_filename)
        Bugsnag.configure(config[releaseStage] ? config[releaseStage] : config) if config
      end

      config = Bugsnag.configuration

      # Fetch and check the api key
      api_key ||= config.api_key
      raise RuntimeError.new("No API key found when notifying deploy") if !api_key || api_key.empty?

      endpoint = (config.use_ssl ? "https://" : "http://") \
                 + (config.endpoint || Bugsnag::Configuration::DEFAULT_ENDPOINT) \
                 + "/deploy"

      parameters = {
        "apiKey" => api_key,
        "releaseStage" => releaseStage,
        "appVersion" => appVersion,
        "revision" => revision,
        "repository" => repository,
        "branch" => branch
      }

      uri = URI.parse(endpoint)
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data(parameters)
      http = Net::HTTP.new(
        uri.host,
        uri.port,
        config.proxy_host,
        config.proxy_port,
        config.proxy_user,
        config.proxy_password
      )
      http.use_ssl = true if config.use_ssl
      http.request(req)

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
