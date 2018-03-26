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

  describe "logger" do
    class TestLogger
      attr_accessor :logs

      def initialize
        @logs = []
      end

      def log(level, message)
        @logs << {
          :level => level,
          :message => message
        }
      end

      def info(msg)
        log('info', msg)
      end

      def warn(msg)
        log('warning', msg)
      end

      def debug(msg)
        log('debug', msg)
      end
    end

    before do
      @logger = TestLogger.new
      @string_regex = /\*\* \[Bugsnag\] (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} (\+\d{4})?): (Info|Warning|Debug) message\n$/
      Bugsnag.configure do |bugsnag|
        bugsnag.logger = @logger
      end
    end

    it "should format a message correctly" do
      formatted_msg = /\*\* \[Bugsnag\] (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} (\+\d{4})?): message\n$/
      expect(Bugsnag.configuration.format_message("message")).to match(formatted_msg)
    end

    it "should log info messages to the set logger" do
      expect(@logger.logs.size).to eq(0)
      Bugsnag.configuration.info("Info message")
      expect(@logger.logs.size).to eq(1)
      log = @logger.logs.first
      expect(log[:level]).to eq('info')
      expect(log[:message]).to match(@string_regex)
    end

    it "should log warning messages to the set logger" do
      expect(@logger.logs.size).to eq(0)
      Bugsnag.configuration.warn("Warning message")
      expect(@logger.logs.size).to eq(1)
      log = @logger.logs.first
      expect(log[:level]).to eq('warning')
      expect(log[:message]).to match(@string_regex)
    end

    it "should log debug messages to the set logger" do
      expect(@logger.logs.size).to eq(0)
      Bugsnag.configuration.debug("Debug message")
      expect(@logger.logs.size).to eq(1)
      log = @logger.logs.first
      expect(log[:level]).to eq('debug')
      expect(log[:message]).to match(@string_regex)
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
