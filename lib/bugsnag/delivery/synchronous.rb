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
            Bugsnag.debug("Notification to #{url} finished, response was #{response.code}, payload was #{body}")
          rescue StandardError => e
            # KLUDGE: Since we don't re-raise http exceptions, this breaks rspec
            raise if e.class.to_s == "RSpec::Expectations::ExpectationNotMetError"

            Bugsnag.warn("Notification to #{url} failed, #{e.inspect}")
            Bugsnag.warn(e.backtrace)
          end
        end

        private

        def request(url, body, configuration)
          uri = URI.parse(url)
          http = Net::HTTP.new(uri.host, uri.port, configuration.proxy_host, configuration.proxy_port, configuration.proxy_user, configuration.proxy_password)
          http.read_timeout = configuration.timeout
          http.open_timeout = configuration.timeout

          if uri.scheme == "https"
            http.use_ssl = true
            # the default in 1.9+, but required for 1.8
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER
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