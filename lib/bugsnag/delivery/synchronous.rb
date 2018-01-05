require "net/https"
require "uri"

module Bugsnag
  module Delivery
    class Synchronous
      BACKOFF_THREADS = {}
      BACKOFF_REQUESTS = {}
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
          # Ensure we have the latest configuration for making these requests
          @latest_configuration = configuration

          BACKOFF_LOCK.lock
          begin
            # Define an exit function once to handle outstanding requests
            @registered_at_exit = false unless defined?(@registered_at_exit)
            if !@registered_at_exit
              @registered_at_exit = true
              at_exit do
                backoff_exit
              end
            end
            if BACKOFF_REQUESTS[url] && !BACKOFF_REQUESTS[url].empty?
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
            if !(BACKOFF_THREADS[url] && BACKOFF_THREADS[url].status)
              spawn_backoff_thread(url)
            end
          ensure
            BACKOFF_LOCK.unlock
          end
        end

        def backoff_exit
          # Kill existing threads
          BACKOFF_THREADS.each do |url, thread|
            thread.exit
          end
          # Retry outstanding requests once, then exit
          BACKOFF_REQUESTS.each do |url, requests|
            requests.map! do |req|
              response = request(url, req[:body], @latest_configuration, req[:options])
              success = req[:options][:success] || '200'
              response.code == success
            end
            requests.reject! { |i| i }
            @latest_configuration.warn("Requests to #{url} finished, #{requests.size} failed")
          end
        end

        def spawn_backoff_thread(url)
          new_thread = Thread.new(url) do |url|
            interval = 2
            while BACKOFF_REQUESTS[url].size > 0
              sleep(interval)
              interval = interval * 2
              interval = 600 if interval > 600
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
          end
          BACKOFF_THREADS[url] = new_thread
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
