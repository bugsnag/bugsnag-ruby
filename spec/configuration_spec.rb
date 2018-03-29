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
end
