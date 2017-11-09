require "net/https"
require "uri"

module Bugsnag
  module Delivery
    class Synchronous
      HEADERS = {"Content-Type" => "application/json"}

      class << self
        def deliver(url, body, configuration)
          begin
            response = request(url, body, configuration)
            configuration.debug("Notification to #{url} finished, response was #{response.code}, payload was #{body}")
          rescue StandardError => e
            # KLUDGE: Since we don't re-raise http exceptions, this breaks rspec
            raise if e.class.to_s == "RSpec::Expectations::ExpectationNotMetError"

            configuration.warn("Notification to #{url} failed, #{e.inspect}")
            configuration.warn(e.backtrace)
          end
        end

        private

        def request(url, body, configuration)
          uri = URI.parse(url)

          if configuration.proxy_host
            http = Net::HTTP.new(uri.host, uri.port, configuration.proxy_host, configuration.proxy_port, configuration.proxy_user, configuration.proxy_password)
          else
            http = Net::HTTP.new(uri.host, uri.port)
          end

          http.read_timeout = configuration.timeout
          http.open_timeout = configuration.timeout

          if uri.scheme == "https"
            http.use_ssl = true
            http.ca_file = configuration.ca_file if configuration.ca_file
          end

          request = Net::HTTP::Post.new(path(uri), HEADERS)
          request.body = body
          http.request(request)
        end

        def path(uri)
          uri.path == "" ? "/" : uri.path
        end
      end
    end
  end
end

Bugsnag::Delivery.register(:synchronous, Bugsnag::Delivery::Synchronous)
