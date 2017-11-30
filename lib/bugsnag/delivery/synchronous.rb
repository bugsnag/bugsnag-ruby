require "net/https"
require "uri"

module Bugsnag
  module Delivery
    class Synchronous
      BACKOFF_THREADS = {}
      BACKOFF_REQUESTS = {}
      BACKOFF_INTERVALS = [0.5, 1, 3, 5, 10, 30, 60, 120, 300, 600]
      BACKOFF_LOCK = Mutex.new

      class << self
        def deliver(url, body, configuration, options={})
          begin
            response = request(url, body, configuration, options)
            configuration.debug("Request to #{url} completed, status: #{response.code}")
            success = options[:success] || '200'
            if options[:backoff] && !(response.code == success)
              backoff(url, body, configuration, options)
            end
          rescue StandardError => e
            # KLUDGE: Since we don't re-raise http exceptions, this breaks rspec
            raise if e.class.to_s == "RSpec::Expectations::ExpectationNotMetError"

            configuration.warn("Notification to #{url} failed, #{e.inspect}")
            configuration.warn(e.backtrace)
          end
        end

        private

        def request(url, body, configuration, options)
          uri = URI.parse(url)

          if options[:trim_payload]
            body = Bugsnag::Helpers.trim_if_needed(body)
          end
          payload = ::JSON.dump(body)

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

          headers = options.key?(:headers) ? options[:headers] : {}
          headers.merge!(default_headers)

          request = Net::HTTP::Post.new(path(uri), headers)
          request.body = payload
          http.request(request)
        end

        def backoff(url, body, configuration, options)
          @latest_configuration = configuration
          BACKOFF_LOCK.lock
          begin
            if BACKOFF_THREADS[url]
              current_thread = BACKOFF_THREADS[url]
              current_thread.exit
            end
            if BACKOFF_REQUESTS[url]
              last_request = BACKOFF_REQUESTS[url].last
              new_body_length = ::JSON.dump(body).length
              old_body_length = ::JSON.dump(last_request[:body]).length
              if new_body_length + old_body_length >= Bugsnag::Helpers::MAX_PAYLOAD_LENGTH
                BACKOFF_REQUESTS[url].push({:body => body, :options => options})
              else
                Bugsnag::Helpers::deep_merge!(last_request, {:body => body, :options => options})
              end
            else
              BACKOFF_REQUESTS[url] = [{:body => body, :options => options}]
            end
            new_thread = Thread.new(url) do |url|
              BACKOFF_INTERVALS.each do |interval|
                sleep(interval)
                BACKOFF_LOCK.lock
                begin
                  BACKOFF_REQUESTS[url].map! do |req|
                    response = request(url, req[:body], @latest_configuration, req[:options])
                    success = req[:options][:success] || '200'
                    if response.code == success
                      @latest_configuration.debug("Request to #{url} completed, status: #{response.code}")
                      false
                    else
                      req
                    end
                  end
                  BACKOFF_REQUESTS[url].reject! { |i| !i }
                ensure
                  BACKOFF_LOCK.unlock
                end
              end
              @latest_configuration.debug("Request to #{url} could not be completed")
            end
            BACKOFF_THREADS[url] = new_thread
          ensure
            BACKOFF_LOCK.unlock
          end
        end

        def path(uri)
          uri.path == "" ? "/" : uri.path
        end

        def default_headers
          {
            "Content-Type" => "application/json",
            "Bugsnag-Sent-At" =>  Time.now().utc().strftime('%Y-%m-%dT%H:%M:%S')
          }
        end
      end
    end
  end
end

Bugsnag::Delivery.register(:synchronous, Bugsnag::Delivery::Synchronous)
