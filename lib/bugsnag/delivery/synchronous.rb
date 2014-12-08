require "net/http"
require "uri"

module Bugsnag
  module Delivery
    class Synchronous
      HEADERS = {"Content-Type" => "application/json"}
      TIMEOUT = 5

      class << self
        def deliver(url, body)
          begin
            response = request(url, body)
            Bugsnag.debug("Notification to #{url} finished, response was #{response.code}, payload was #{body}")
          rescue StandardError => e
            # KLUDGE: Since we don't re-raise http exceptions, this breaks rspec
            raise if e.class.to_s == "RSpec::Expectations::ExpectationNotMetError"

            Bugsnag.warn("Notification to #{url} failed, #{e.inspect}")
            Bugsnag.warn(e.backtrace)
          end
        end

        private

        def request(url, body)
          uri = URI.parse(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = TIMEOUT
          http.open_timeout = TIMEOUT
          http.use_ssl = true if uri.scheme == "https"

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
