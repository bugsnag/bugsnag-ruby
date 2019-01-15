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

  describe "disable_sessions" do
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

  it "should have exit exception classes ignored by default" do
    expect(subject.ignore_classes).to eq(Set.new([SystemExit, SignalException]))
  end

end
