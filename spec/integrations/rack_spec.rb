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

      expect(Bugsnag.configuration.runtime_versions["rack"]).to_not be nil
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

    it "correctly redacts from url and referer any value indicated by meta_data_filters" do
      callback = double
      rack_env = {
        :env => true,
        :HTTP_REFERER => "https://bugsnag.com/about?email=hello@world.com&another_param=thing",
        "rack.session" => {
          :session => true
        }
      }

      rack_request = double
      rack_params = {
        :param => 'test'
      }
      allow(rack_request).to receive_messages(
        :params => rack_params,
        :ip => "rack_ip",
        :request_method => "TEST",
        :path => "/TEST_PATH",
        :scheme => "http",
        :host => "test_host",
        :port => 80,
        :referer => "https://bugsnag.com/about?email=hello@world.com&another_param=thing",
        :fullpath => "/TEST_PATH?email=hello@world.com&another_param=thing"
      )
      expect(::Rack::Request).to receive(:new).with(rack_env).and_return(rack_request)

      # modify rack_env to include redacted referer
      report = double("Bugsnag::Report")
      allow(report).to receive(:request_data).and_return({
        :rack_env => rack_env
      })
      expect(report).to receive(:context=).with("TEST /TEST_PATH")
      expect(report).to receive(:user).and_return({})

      config = double
      allow(config).to receive(:send_environment).and_return(true)
      allow(config).to receive(:meta_data_filters).and_return(['email'])
      allow(report).to receive(:configuration).and_return(config)
      expect(report).to receive(:add_tab).once.with(:request, {
        :url => "http://test_host/TEST_PATH?email=[FILTERED]&another_param=thing",
        :httpMethod => "TEST",
        :params => rack_params,
        :referer => "https://bugsnag.com/about?email=[FILTERED]&another_param=thing",
        :clientIp => "rack_ip",
        :headers => {
          "Referer" => "https://bugsnag.com/about?email=[FILTERED]&another_param=thing"
        }
      })
      # rack_env["HTTP_REFERER"] = "https://bugsnag.com/about?email=[FILTERED]&another_param=thing"
      expect(report).to receive(:add_tab).once.with(:environment, rack_env)
      expect(report).to receive(:add_tab).once.with(:session, {
        :session => true
      })

      expect(callback).to receive(:call).with(report)

      middleware = Bugsnag::Middleware::RackRequest.new(callback)
      middleware.call(report)
    end

    it "correctly extracts data from rack middleware" do
      callback = double
      rack_env = {
        :env => true,
        :HTTP_test_key => "test_key",
        "rack.session" => {
          :session => true
        }
      }

      rack_request = double
      rack_params = {
        :param => 'test'
      }
      allow(rack_request).to receive_messages(
        :params => rack_params,
        :ip => "rack_ip",
        :request_method => "TEST",
        :path => "/TEST_PATH",
        :scheme => "http",
        :host => "test_host",
        :port => 80,
        :referer => "referer",
        :fullpath => "/TEST_PATH"
      )
      expect(Rack::Request).to receive(:new).with(rack_env).and_return(rack_request)

      report = double("Bugsnag::Report")
      allow(report).to receive(:request_data).and_return({
        :rack_env => rack_env
      })
      expect(report).to receive(:context=).with("TEST /TEST_PATH")
      expect(report).to receive(:user).and_return({})

      config = double
      allow(config).to receive(:send_environment).and_return(true)
      allow(config).to receive(:meta_data_filters).and_return(nil)
      allow(report).to receive(:configuration).and_return(config)
      expect(report).to receive(:add_tab).once.with(:environment, rack_env)
      expect(report).to receive(:add_tab).once.with(:request, {
        :url => "http://test_host/TEST_PATH",
        :httpMethod => "TEST",
        :params => rack_params,
        :referer => "referer",
        :clientIp => "rack_ip",
        :headers => {
          "Test-Key" => "test_key"
        }
      })
      expect(report).to receive(:add_tab).once.with(:session, {
        :session => true
      })

      expect(callback).to receive(:call).with(report)

      middleware = Bugsnag::Middleware::RackRequest.new(callback)
      middleware.call(report)
    end

    after do
      Object.send(:remove_const, :Rack) if @mocked_rack
    end

  end

  it "don't mess with middlewares list on each req" do
    app = lambda { |env| ['200', {}, ['']] }

    Bugsnag::Rack.new(app)

    expect { 2.times { Bugsnag::Rack.new(app) } }.not_to change {
      Bugsnag.configuration.middleware.instance_variable_get(:@middlewares)
    }
  end
end
