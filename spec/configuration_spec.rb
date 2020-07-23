# encoding: utf-8
require 'spec_helper'

describe Bugsnag::Configuration do
  describe "delivery_method" do
    it "should have the default delivery method" do
      expect(subject.delivery_method).to eq(:thread_queue)
    end

    it "should have the defined delivery_method" do
      subject.delivery_method = :test
      expect(subject.delivery_method).to eq(:test)
    end

    it "should allow a new default delivery_method to be set" do
      subject.default_delivery_method = :test
      expect(subject.delivery_method).to eq(:test)
    end

    it "should allow the delivery_method to be set over a default" do
      subject.default_delivery_method = :test
      subject.delivery_method = :wow
      expect(subject.delivery_method).to eq(:wow)
    end
  end

  describe "release_stage" do
    after(:each) do
      ENV["BUGSNAG_RELEASE_STAGE"] = nil
    end

    it "has no default value" do
      expect(subject.release_stage).to be_nil
    end

    it "uses the 'BUGSNAG_RELEASE_STAGE' environment variable if set" do
      ENV["BUGSNAG_RELEASE_STAGE"] = "foobar"
      expect(subject.release_stage).to eq("foobar")
    end
  end

  describe "#notify_endpoint" do
    it "defaults to DEFAULT_NOTIFY_ENDPOINT" do
      expect(subject.notify_endpoint).to eq(Bugsnag::Configuration::DEFAULT_NOTIFY_ENDPOINT)
    end

    it "is readonly" do
      expect{ subject.notify_endpoint = "My Custom Url" }.to raise_error(NoMethodError)
    end

    it "is the same as endpoint" do
      expect(subject.notify_endpoint).to equal(subject.endpoint)
    end
  end

  describe "#session_endpoint" do
    it "defaults to DEFAULT_SESSION_ENDPOINT" do
      expect(subject.session_endpoint).to eq(Bugsnag::Configuration::DEFAULT_SESSION_ENDPOINT)
    end
  end

  describe "#auto_capture_sessions" do
    it "defaults to true" do
      expect(subject.auto_capture_sessions).to eq(true)
    end
  end

  describe "#enable_sessions" do
    it "defaults to true" do
      expect(subject.enable_sessions).to eq(true)
    end

    it "is readonly" do
      expect{ subject.enable_sessions = true }.to raise_error(NoMethodError)
    end
  end

  describe "#endpoint=" do
    let(:custom_notify_endpoint) { "My custom notify endpoint" }
    let(:session_endpoint) { "My session endpoint" }
    it "calls #warn with a deprecation notice" do
      allow(subject).to receive(:set_endpoints)
      expect(subject).to receive(:warn).with("The 'endpoint' configuration option is deprecated. The 'set_endpoints' method should be used instead")
      subject.endpoint = custom_notify_endpoint
    end

    it "calls #set_endpoints with the new notify_endpoint and existing session endpoint" do
      allow(subject).to receive(:session_endpoint).and_return(session_endpoint)
      allow(subject).to receive(:warn)
      expect(subject).to receive(:set_endpoints).with(custom_notify_endpoint, session_endpoint)
      subject.endpoint = custom_notify_endpoint
    end
  end

  describe "#session_endpoint=" do
    let(:notify_endpoint) { "My notify endpoint" }
    let(:custom_session_endpoint) { "My custom session endpoint" }
    it "calls #warn with a deprecation notice" do
      allow(subject).to receive(:set_endpoints)
      expect(subject).to receive(:warn).with("The 'session_endpoint' configuration option is deprecated. The 'set_endpoints' method should be used instead")
      subject.session_endpoint = custom_session_endpoint
    end

    it "calls #set_endpoints with the existing notify_endpoint and new session endpoint" do
      allow(subject).to receive(:notify_endpoint).and_return(notify_endpoint)
      allow(subject).to receive(:warn)
      expect(subject).to receive(:set_endpoints).with(notify_endpoint, custom_session_endpoint)
      subject.session_endpoint = custom_session_endpoint
    end
  end

  describe "#set_endpoints" do
    let(:custom_notify_endpoint) { "My custom notify endpoint" }
    let(:custom_session_endpoint) { "My custom session endpoint" }
    it "set notify_endpoint and session_endpoint" do
      subject.set_endpoints(custom_notify_endpoint, custom_session_endpoint)
      expect(subject.notify_endpoint).to eq(custom_notify_endpoint)
      expect(subject.session_endpoint).to eq(custom_session_endpoint)
    end
  end

  describe "#disable_sessions" do
    it "sets #send_session and #auto_capture_sessions to false" do
      subject.disable_sessions
      expect(subject.auto_capture_sessions).to be false
      expect(subject.enable_sessions).to be false
    end
  end

  describe "set_proxy" do
    it "defaults proxy settings to nil" do
      expect(subject.proxy_host).to be nil
      expect(subject.proxy_port).to be nil
      expect(subject.proxy_user).to be nil
      expect(subject.proxy_password).to be nil
    end

    it "allows proxy settings to be set directly" do
      subject.proxy_host = "http://localhost"
      subject.proxy_port = 34000
      subject.proxy_user = "user"
      subject.proxy_password = "password"
      expect(subject.proxy_host).to eq("http://localhost")
      expect(subject.proxy_port).to eq(34000)
      expect(subject.proxy_user).to eq("user")
      expect(subject.proxy_password).to eq("password")
    end

    it "parses a uri if provided" do
      subject.parse_proxy("http://user:password@localhost:34000")
      expect(subject.proxy_host).to eq("localhost")
      expect(subject.proxy_port).to eq(34000)
      expect(subject.proxy_user).to eq("user")
      expect(subject.proxy_password).to eq("password")
    end

    it "automatically parses http_proxy environment variable" do
      ENV['http_proxy'] = "http://user:password@localhost:34000"
      expect(subject.proxy_host).to eq("localhost")
      expect(subject.proxy_port).to eq(34000)
      expect(subject.proxy_user).to eq("user")
      expect(subject.proxy_password).to eq("password")
    end

    it "automatically parses https_proxy environment variable" do
      ENV['https_proxy'] = "https://user:password@localhost:34000"
      expect(subject.proxy_host).to eq("localhost")
      expect(subject.proxy_port).to eq(34000)
      expect(subject.proxy_user).to eq("user")
      expect(subject.proxy_password).to eq("password")
    end

    after do
      ENV['http_proxy'] = nil
      ENV['https_proxy'] = nil
    end
  end

  describe "#hostname" do
    it "has a default value" do
      expect(subject.hostname.length).to be > 0
    end

    it "has a value set by Socket" do
      expect(subject.hostname).to eq(Socket.gethostname)
    end

    it "has a value set by DYNO environment variable" do
      ENV['DYNO'] = 'localhost'
      expect(subject.hostname).to eq("localhost")
    end

    after do
      ENV['DYNO'] = nil
    end
  end

  describe "#runtime_versions" do
    it "has a default value" do
      expect(subject.runtime_versions.length).to be > 0
      expect(subject.runtime_versions["ruby"]).to eq(RUBY_VERSION)
    end

    it "has a settable value" do
      subject.runtime_versions["ruby"] = '9.9.9'
      expect(subject.runtime_versions["ruby"]).to eq('9.9.9')
    end
  end

  describe "logger" do
    class TestLogger
      attr_accessor :logs

      def initialize
        @logs = []
      end

      def log(level, name, &block)
        message = block.call
        @logs << {
          :level => level,
          :name => name,
          :message => message
        }
      end

      def info(name, &block)
        log('info', name, &block)
      end

      def warn(name, &block)
        log('warning', name, &block)
      end

      def debug(name, &block)
        log('debug', name, &block)
      end
    end

    before do
      @logger = TestLogger.new
      Bugsnag.configure do |bugsnag|
        bugsnag.logger = @logger
      end
    end

    context "using configure" do
      before do
        Bugsnag.configuration.api_key = nil
        Bugsnag.instance_variable_set("@key_warning", nil)
        ENV['BUGSNAG_API_KEY'] = nil
        expect(@logger.logs.size).to eq(0)
      end

      context "API key is not specified" do
        it "skips logging a warning if validate_api_key is false" do
          Bugsnag.configure(false)
          expect(@logger.logs.size).to eq(0)
        end

        it "logs a warning by default" do
          Bugsnag.configure
          expect(@logger.logs.size).to eq(1)
          log = @logger.logs.first
          expect(log).to eq({
            :level => "warning",
            :name => "[Bugsnag]",
            :message => "No valid API key has been set, notifications will not be sent"
          })
        end

        it "logs a warning if validate_api_key is true" do
          Bugsnag.configure(true)
          expect(@logger.logs.size).to eq(1)
          log = @logger.logs.first
          expect(log).to eq({
            :level => "warning",
            :name => "[Bugsnag]",
            :message => "No valid API key has been set, notifications will not be sent"
          })
        end
      end

      context "API key is set" do
        it "skips logging a warning when configuring with an API key" do
          Bugsnag.configure do |config|
            config.api_key = 'd57a2472bd130ac0ab0f52715bbdc600'
          end
          expect(@logger.logs.size).to eq(0)
        end

        it "logs a warning if the configured API key is invalid" do
          Bugsnag.configure do |config|
            config.api_key = 'WARNING: not a real key'
          end
          expect(@logger.logs.size).to eq(1)
          log = @logger.logs.first
          expect(log).to eq({
            :level => "warning",
            :name => "[Bugsnag]",
            :message => "No valid API key has been set, notifications will not be sent"
          })
        end
      end
    end

    it "should log info messages to the set logger" do
      expect(@logger.logs.size).to eq(0)
      Bugsnag.configuration.info("Info message")
      expect(@logger.logs.size).to eq(1)
      log = @logger.logs.first
      expect(log).to eq({
        :level => "info",
        :name => "[Bugsnag]",
        :message => "Info message"
      })
    end

    it "should log warning messages to the set logger" do
      expect(@logger.logs.size).to eq(0)
      Bugsnag.configuration.warn("Warning message")
      expect(@logger.logs.size).to eq(1)
      log = @logger.logs.first
      expect(log).to eq({
        :level => "warning",
        :name => "[Bugsnag]",
        :message => "Warning message"
      })
    end

    it "should log debug messages to the set logger" do
      expect(@logger.logs.size).to eq(0)
      Bugsnag.configuration.debug("Debug message")
      expect(@logger.logs.size).to eq(1)
      log = @logger.logs.first
      expect(log).to eq({
        :level => "debug",
        :name => "[Bugsnag]",
        :message => "Debug message"
      })
    end

    after do
      Bugsnag.configure do |bugsnag|
        bugsnag.logger = Logger.new(StringIO.new)
      end
    end
  end

  it "should have exit exception classes in ignore_classes by default" do
    expect(subject.ignore_classes).to eq(Set.new([SystemExit, SignalException]))
  end

  it "should have nothing in discard_classes by default" do
    expect(subject.discard_classes).to eq(Set.new([]))
  end

  describe "#breadcrumbs" do
    it "first returns a new circular buffer" do
      buffer = subject.breadcrumbs

      expect(buffer).to be_a(Bugsnag::Utility::CircularBuffer)
      expect(buffer.to_a).to eq([])
    end

    it "returns the same buffer in repeated calls" do
      buffer = subject.breadcrumbs
      buffer << 1
      second_buffer = subject.breadcrumbs

      expect(second_buffer.to_a).to eq([1])
    end

    it "returns a different buffer on different threads" do
      buffer = subject.breadcrumbs
      buffer << 1

      second_buffer = nil
      Thread.new { second_buffer = subject.breadcrumbs; second_buffer << 2 }.join

      expect(buffer.to_a).to eq([1])
      expect(second_buffer.to_a).to eq([2])
    end

    it "sets max_items to the current max_breadcrumbs size" do
      expect(subject.breadcrumbs.max_items).to eq(subject.max_breadcrumbs)
    end
  end

  describe "#max_breadcrumbs" do
    it "defaults to DEFAULT_MAX_BREADCRUMBS" do
      expect(subject.max_breadcrumbs).to eq(Bugsnag::Configuration::DEFAULT_MAX_BREADCRUMBS)
    end
  end

  describe "#max_breadcrumbs=" do
    it "sets the value of max_breadcrumbs" do
      subject.max_breadcrumbs = 10
      expect(subject.max_breadcrumbs).to eq(10)
    end

    it "sets the max_items property of the breadcrumbs buffer" do
      buffer = subject.breadcrumbs

      expect(buffer.max_items).to eq(Bugsnag::Configuration::DEFAULT_MAX_BREADCRUMBS)

      subject.max_breadcrumbs = 5

      expect(buffer.max_items).to eq(5)
    end
  end

  describe "#enabled_automatic_breadcrumb_types" do
    it "defaults to Bugsnag::Breadcrumbs::VALID_BREADCRUMB_TYPES" do
      expect(subject.enabled_automatic_breadcrumb_types).to eq(Bugsnag::Breadcrumbs::VALID_BREADCRUMB_TYPES)
    end

    it "is an editable array" do
      subject.enabled_automatic_breadcrumb_types << "Some custom type"
      expect(subject.enabled_automatic_breadcrumb_types).to include("Some custom type")
    end
  end

  describe "#before_breadcrumb_callbacks" do
    it "initially returns an empty array" do
      expect(subject.before_breadcrumb_callbacks).to eq([])
    end

    it "stores the array between subsequent calls" do
      first_call = subject.before_breadcrumb_callbacks
      first_call << 1

      second_call = subject.before_breadcrumb_callbacks

      expect(second_call).to eq([1])
    end

    it "stays the same across threads" do
      first_array = subject.before_breadcrumb_callbacks
      first_array << 1

      second_array = nil
      Thread.new { second_array = subject.before_breadcrumb_callbacks; second_array << 2}.join

      expect(first_array).to eq([1, 2])
      expect(second_array).to eq([1, 2])
    end
  end

  describe "#vendor_path" do
    it "returns the default vendor path" do
      expect(subject.vendor_path).to eq(Bugsnag::Configuration::DEFAULT_VENDOR_PATH)
    end

    it "returns the defined vendor path" do
      subject.vendor_path = /foo/
      expect(subject.vendor_path).to eq(/foo/)
    end
  end
end
