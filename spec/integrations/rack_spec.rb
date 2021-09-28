require 'spec_helper'

describe Bugsnag::Rack do
  it "calls the upstream rack app with the environment" do
    rack_env = {"key" => "value"}
    app = lambda { |env| ['response', {}, env] }
    rack_stack = Bugsnag::Rack.new(app)

    response = rack_stack.call(rack_env)

    expect(response).to eq(['response', {}, rack_env])
  end

  context "when an exception is raised in rack middleware" do
    # Build a fake crashing rack app
    exception = BugsnagTestException.new("It crashed")
    rack_env = {"key" => "value"}
    app = lambda { |env| raise exception }
    rack_stack = Bugsnag::Rack.new(app)

    before do
      unless defined?(::Rack)
        @mocked_rack = true
        class Rack
          def self.release
            '9.9.9'
          end
          class Request
          end
        end
      end
    end

    it "re-raises the exception" do
      expect { rack_stack.call(rack_env) }.to raise_error(BugsnagTestException)
    end

    it "delivers an exception if auto_notify is enabled" do
      rack_stack.call(rack_env) rescue nil

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        exception_class = payload["events"].first["exceptions"].first["errorClass"]
        expect(exception_class).to eq(exception.class.to_s)
      }

    end

    it "applies the correct severity reason" do
      rack_stack.call(rack_env) rescue nil

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["unhandled"]).to be true
        expect(event["severityReason"]).to eq({
          "type" => "unhandledExceptionMiddleware",
          "attributes" => {
            "framework" => "Rack"
          }
        })
      }
    end

    it "applies the rack version" do
      app = lambda { |env| raise BugsnagTestException.new("It crashed") }
      rack_stack = Bugsnag::Rack.new(app)

      expect(Bugsnag.configuration.runtime_versions["rack"]).to eq '9.9.9'
    end

    it "does not deliver an exception if auto_notify is disabled" do
      Bugsnag.configure do |config|
        config.auto_notify = false
      end

      rack_stack.call(rack_env) rescue nil

      expect(Bugsnag).not_to have_sent_notification
    end
  end

  context "when running against the middleware" do
    before do
      unless defined?(::Rack)
        @mocked_rack = true
        class Rack
          def self.release
            '9.9.9'
          end
          class Request
          end
        end
      end
    end

    after do
      Object.send(:remove_const, :Rack) if @mocked_rack
    end

    it "correctly redacts from url and referer any value indicated by meta_data_filters" do
      rack_env = {
        env: true,
        HTTP_REFERER: "https://bugsnag.com/about?email=hello@world.com&another_param=thing",
        "rack.session" => { session: true }
      }

      rack_request = double
      allow(rack_request).to receive_messages(
        params: { param: 'test', param2: 'test2' },
        ip: "rack_ip",
        request_method: "TEST",
        path: "/TEST_PATH",
        scheme: "http",
        host: "test_host",
        port: 80,
        referer: "https://bugsnag.com/about?email=hello@world.com&another_param=thing",
        fullpath: "/TEST_PATH?email=hello@world.com&another_param=thing",
        form_data?: true,
        POST: { param: 'test' },
        cookies: { session_id: 12345 }
      )

      expect(::Rack::Request).to receive(:new).with(rack_env).and_return(rack_request)

      Bugsnag.configure do |config|
        config.send_environment = true
        config.meta_data_filters << 'email'
        config.request_data[:rack_env] = rack_env
      end

      report = Bugsnag::Report.new(RuntimeError.new('abc'), Bugsnag.configuration)

      callback = double
      expect(callback).to receive(:call).with(report)

      middleware = Bugsnag::Middleware::RackRequest.new(callback)
      middleware.call(report)

      expect(report.request).to eq({
        url: "http://test_host/TEST_PATH?email=[FILTERED]&another_param=thing",
        httpMethod: "TEST",
        params: { param: 'test', param2: 'test2' },
        referer: "https://bugsnag.com/about?email=[FILTERED]&another_param=thing",
        clientIp: "rack_ip",
        headers: {
          "Referer" => "https://bugsnag.com/about?email=[FILTERED]&another_param=thing"
        },
        body: { param: 'test' }
      })

      expect(report.metadata[:request]).to be(report.request)
      expect(report.metadata[:environment]).to eq(rack_env)
      expect(report.metadata[:session]).to eq({ session: true })
    end

    it "correctly extracts data from rack middleware" do
      rack_env = {
        env: true,
        HTTP_test_key: "test_key",
        "SERVER_PROTOCOL" => "HTTP/1.0",
        "rack.session" => { session: true }
      }

      rack_request = double
      allow(rack_request).to receive_messages(
        params: { param: 'test', param2: 'test2' },
        ip: "rack_ip",
        request_method: "TEST",
        path: "/TEST_PATH",
        scheme: "http",
        host: "test_host",
        port: 80,
        referer: "referer",
        fullpath: "/TEST_PATH",
        form_data?: true,
        POST: { param: 'test' },
        cookies: { session_id: 12345 }
      )

      expect(Rack::Request).to receive(:new).with(rack_env).and_return(rack_request)

      Bugsnag.configure do |config|
        config.send_environment = true
        config.meta_data_filters = []
        config.request_data[:rack_env] = rack_env
      end

      report = Bugsnag::Report.new(RuntimeError.new('abc'), Bugsnag.configuration)

      callback = double
      expect(callback).to receive(:call).with(report)

      middleware = Bugsnag::Middleware::RackRequest.new(callback)
      middleware.call(report)

      expect(report.request).to eq({
        url: "http://test_host/TEST_PATH",
        httpMethod: "TEST",
        httpVersion: "HTTP/1.0",
        params: { param: 'test', param2: 'test2' },
        referer: "referer",
        clientIp: "rack_ip",
        headers: { "Test-Key" => "test_key" },
        body: { param: 'test' },
        cookies: { session_id: 12345 }
      })

      expect(report.metadata[:request]).to be(report.request)
      expect(report.metadata[:environment]).to eq(rack_env)
      expect(report.metadata[:session]).to eq({ session: true })
    end

    it "doesn't extract the request body or cookies if they are empty" do
      rack_env = {
        env: true,
        HTTP_test_key: "test_key",
        "rack.session" => { session: true }
      }

      rack_request = double
      allow(rack_request).to receive_messages(
        params: { param: 'test', param2: 'test2' },
        ip: "rack_ip",
        request_method: "TEST",
        path: "/TEST_PATH",
        scheme: "http",
        host: "test_host",
        port: 80,
        referer: "referer",
        fullpath: "/TEST_PATH",
        # no post data or cookies
        form_data?: true,
        POST: {},
        cookies: {}
      )

      expect(Rack::Request).to receive(:new).with(rack_env).and_return(rack_request)

      Bugsnag.configure do |config|
        config.send_environment = true
        config.meta_data_filters = []
        config.request_data[:rack_env] = rack_env
      end

      report = Bugsnag::Report.new(RuntimeError.new('abc'), Bugsnag.configuration)

      callback = double
      expect(callback).to receive(:call).with(report)

      middleware = Bugsnag::Middleware::RackRequest.new(callback)
      middleware.call(report)

      expect(report.request).to eq({
        url: "http://test_host/TEST_PATH",
        httpMethod: "TEST",
        params: { param: 'test', param2: 'test2' },
        referer: "referer",
        clientIp: "rack_ip",
        headers: { "Test-Key" => "test_key" }
      })

      expect(report.metadata[:request]).to be(report.request)
    end

    it "parses JSON body if the content type is 'application/json'" do
      rack_env = {
        env: true,
        HTTP_REFERER: "https://bugsnag.com/about?email=hello@world.com&another_param=thing",
        "CONTENT_TYPE" => "application/json",
        "rack.session" => { session: true }
      }

      request_body = StringIO.new('{ "param": "test", "another": "param" }')
      expect(request_body.pos).to eq(0)

      rack_request = double
      allow(rack_request).to receive_messages(
        params: { param: 'test', param2: 'test2' },
        ip: "rack_ip",
        request_method: "TEST",
        path: "/TEST_PATH",
        scheme: "http",
        host: "test_host",
        port: 80,
        referer: "https://bugsnag.com/about?email=hello@world.com&another_param=thing",
        fullpath: "/TEST_PATH?email=hello@world.com&another_param=thing",
        form_data?: false,
        POST: {},
        cookies: { session_id: 12345 },
        body: request_body
      )

      expect(::Rack::Request).to receive(:new).with(rack_env).and_return(rack_request)

      Bugsnag.configure do |config|
        config.send_environment = true
        config.meta_data_filters << 'email'
        config.request_data[:rack_env] = rack_env
      end

      report = Bugsnag::Report.new(RuntimeError.new('abc'), Bugsnag.configuration)

      callback = double
      expect(callback).to receive(:call).with(report)

      middleware = Bugsnag::Middleware::RackRequest.new(callback)
      middleware.call(report)

      # ensure the request body was rewound
      expect(request_body.pos).to eq(0)

      expect(report.request).to eq({
        url: "http://test_host/TEST_PATH?email=[FILTERED]&another_param=thing",
        httpMethod: "TEST",
        params: { param: 'test', param2: 'test2' },
        referer: "https://bugsnag.com/about?email=[FILTERED]&another_param=thing",
        clientIp: "rack_ip",
        headers: {
          "Content-Type" => "application/json",
          "Referer" => "https://bugsnag.com/about?email=[FILTERED]&another_param=thing"
        },
        body: { "param" => "test", "another" => "param" }
      })

      expect(report.metadata[:request]).to be(report.request)
      expect(report.metadata[:environment]).to eq(rack_env)
      expect(report.metadata[:session]).to eq({ session: true })
    end

    it "doesn't crash when given an invalid JSON body" do
      rack_env = {
        env: true,
        HTTP_REFERER: "https://bugsnag.com/about?email=hello@world.com&another_param=thing",
        "CONTENT_TYPE" => "application/json",
        "rack.session" => { session: true }
      }

      request_body = StringIO.new("{{{{{{{{{{{{{{")

      rack_request = double
      allow(rack_request).to receive_messages(
        params: { param: 'test', param2: 'test2' },
        ip: "rack_ip",
        request_method: "TEST",
        path: "/TEST_PATH",
        scheme: "http",
        host: "test_host",
        port: 80,
        referer: "https://bugsnag.com/about?email=hello@world.com&another_param=thing",
        fullpath: "/TEST_PATH?email=hello@world.com&another_param=thing",
        form_data?: false,
        POST: {},
        cookies: { session_id: 12345 },
        body: request_body
      )

      expect(::Rack::Request).to receive(:new).with(rack_env).and_return(rack_request)

      Bugsnag.configure do |config|
        config.send_environment = true
        config.meta_data_filters << 'email'
        config.request_data[:rack_env] = rack_env
      end

      report = Bugsnag::Report.new(RuntimeError.new('abc'), Bugsnag.configuration)

      callback = double
      expect(callback).to receive(:call).with(report)

      middleware = Bugsnag::Middleware::RackRequest.new(callback)
      middleware.call(report)

      # ensure the request body was rewound
      expect(request_body.pos).to eq(0)

      expect(report.request).to eq({
        url: "http://test_host/TEST_PATH?email=[FILTERED]&another_param=thing",
        httpMethod: "TEST",
        params: { param: 'test', param2: 'test2' },
        referer: "https://bugsnag.com/about?email=[FILTERED]&another_param=thing",
        clientIp: "rack_ip",
        headers: {
          "Content-Type" => "application/json",
          "Referer" => "https://bugsnag.com/about?email=[FILTERED]&another_param=thing"
        }
        # no request body as we couldn't parse it
      })

      expect(report.metadata[:request]).to be(report.request)
      expect(report.metadata[:environment]).to eq(rack_env)
      expect(report.metadata[:session]).to eq({ session: true })
    end
  end

  it "doesn't change the middleware list on each request" do
    app = lambda { |env| ['200', {}, ['']] }

    Bugsnag::Rack.new(app)

    expect { 2.times { Bugsnag::Rack.new(app) } }.not_to change {
      Bugsnag.configuration.middleware.instance_variable_get(:@middlewares)
    }
  end
end
