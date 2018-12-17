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

    it "should have sensible defaults for session tracking" do
      expect(subject.session_endpoint).to eq("https://sessions.bugsnag.com")
      expect(subject.auto_capture_sessions).to be false
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
    expect(subject.ignore_classes).to eq(Set.new([SystemExit, Interrupt]))
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
end
