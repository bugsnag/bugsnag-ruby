require "net/https"
require "uri"

module Bugsnag
  module Delivery
    class Synchronous
      HEADERS = {"Content-Type" => "application/json"}
      BACKOFF_INTERVALS = [0.5, 1, 3, 5, 10, 30, 60, 120, 300, 600]
      SUCCESS_REGEX = /^2\d{2}$/

      class << self
        def deliver(url, body, configuration, headers={}, backoff=false)
          begin
            response = request(url, body, configuration, headers)
            configuration.debug("Request to #{url} completed, status: #{response.code}")
            if backoff && !(SUCCESS_REGEX.match(response.code))
              backoff(url, body, configuration, headers)
            end
          rescue StandardError => e
            # KLUDGE: Since we don't re-raise http exceptions, this breaks rspec
            raise if e.class.to_s == "RSpec::Expectations::ExpectationNotMetError"

            configuration.warn("Notification to #{url} failed, #{e.inspect}")
            configuration.warn(e.backtrace)
          end
        end

        private

        def request(url, body, configuration, headers={})
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

          headers = headers.merge(HEADERS)

          request = Net::HTTP::Post.new(path(uri), headers)
          request.body = body
          http.request(request)
        end

        def backoff(url, body, configuration, headers={})
          Thread.new do
            BACKOFF_INTERVALS.each do |interval|
              sleep(interval)
              response = request(url, body, configuration, headers)
              if [200, 202].include?(response.code)
                configuration.debug("Request to #{url} completed, status: #{response.code}")
                break
              end
            end
          end
        end

        def path(uri)
          uri.path == "" ? "/" : uri.path
        end
      end
    end
  end
end

Bugsnag::Delivery.register(:synchronous, Bugsnag::Delivery::Synchronous)
