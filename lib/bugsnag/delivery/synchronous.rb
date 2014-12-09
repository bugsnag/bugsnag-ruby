module Bugsnag
  module Delivery
    class Synchronous
      HEADERS = {"Content-Type" => "application/json"}
      TIMEOUT = 5

      class << self
        def deliver(url, body)
          begin
            response = HTTParty.post(url, {:body => body, :headers => HEADERS, :timeout => TIMEOUT})
            Bugsnag.debug("Notification to #{url} finished, response was #{response.code}, payload was #{body}")
          rescue StandardError => e
            # KLUDGE: Since we don't re-raise http exceptions, this breaks rspec
            raise if e.class.to_s == "RSpec::Expectations::ExpectationNotMetError"

            Bugsnag.warn("Notification to #{url} failed, #{e.inspect}")
            Bugsnag.warn(e.backtrace)
          end
        end
      end
    end
  end
end

Bugsnag::Delivery.register(:synchronous, Bugsnag::Delivery::Synchronous)
