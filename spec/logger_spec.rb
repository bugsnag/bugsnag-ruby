# encoding: utf-8

require 'spec_helper'
require 'logger'
require 'bugsnag/loggers/logger'
require 'bugsnag/loggers/log_device'

describe Bugsnag::Loggers do
  
  context "a log device" do
    before do
      @log_device = Bugsnag::Loggers::LogDevice.new
    end

    it "writes by default" do
      expect(Bugsnag).to receive(:leave_breadcrumb).with(
        "message",
        "log",
        {
          :progname => nil,
          :severity => "unknown"
        }
      )
      @log_device.write "message"
    end

    it "doesn't write when closed" do
      expect(Bugsnag).to_not receive(:leave_breadcrumb)
      @log_device.close
      @log_device.write "message"
    end

    it "writes after being re-opened" do
      expect(Bugsnag).to receive(:leave_breadcrumb).with(
        "message",
        "log",
        {
          :progname => nil,
          :severity => "unknown"
        }
      )
      @log_device.close
      @log_device.reopen
      @log_device.write "message"
    end

    it "allows a progname and severity" do
      expect(Bugsnag).to receive(:leave_breadcrumb).with(
        "message",
        "log",
        {
          :progname => "logTests",
          :severity => "info"
        }
      )
      @log_device.write "message", "logTests", "info"
    end
  end

  context "a logger" do
    before do
      @logger = Bugsnag::Loggers::Logger.new
    end

    it "is a logger and a bugsnag logger" do
      expect(@logger.class.ancestors).to include(Bugsnag::Loggers::Logger, Logger)
    end

    it "logs a breadcrumb when add is called" do
      expect(Bugsnag).to receive(:leave_breadcrumb).with(
        "message",
        "log",
        {
          :progname => nil,
          :severity => "info"
        }
      )
      @logger.add Logger::INFO, "message"
    end

    it "logs a breadcrumb when << is called" do
      expect(Bugsnag).to receive(:leave_breadcrumb).with(
        "message",
        "log",
        {
          :progname => nil,
          :severity => "unknown"
        }
      )
      @logger << "message"
    end
  end
end

    