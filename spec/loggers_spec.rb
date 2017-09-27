# encoding: utf-8

require 'spec_helper'
require 'bugsnag/loggers/bugsnag_logger'
require 'bugsnag/loggers/multi_logger'

describe Bugsnag::Loggers do
  
  context "a bugsnag logger" do

    before do
      @logger = Bugsnag::Loggers::BugsnagLogger.new
    end

    it "has a default level of info" do
      expect(@logger.level).to eq("info")
    end

    it "allows the level to be changed" do
      @logger.level = "warn"
      expect(@logger.level).to eq("warn")
      @logger.sev_threshold = "error"
      expect(@logger.level).to eq("error")
    end

    it "logs when add is called" do
      expect(Bugsnag).to receive(:leave_breadcrumb).with(
        "message",
        "log",
        {
          :progname => "progname",
          :severity => "error"
        }
      )
      @logger.add("error", "message", "progname")
    end

    it "doesn't log when the severity is too low" do
      expect(Bugsnag).to_not receive(:leave_breadcrumb).with(
        "message",
        "log",
        {
          :progname => "progname",
          :severity => "error"
        }
      )
      @logger.level = "fatal"
      @logger.add("error", "message", "progname")
    end

    it "won't log when closed" do
      expect(Bugsnag).to_not receive(:leave_breadcrumb).with(
        "message",
        "log",
        {
          :progname => "progname",
          :severity => "error"
        }
      )
      expect(@logger.close).to be true
      @logger.add("error", "message", "progname")
    end

    it "will log if reopened" do
      expect(Bugsnag).to receive(:leave_breadcrumb).with(
        "message",
        "log",
        {
          :progname => "progname",
          :severity => "error"
        }
      )

      expect(@logger.close).to be true
      expect(@logger.reopen).to be true
      @logger.add("error", "message", "progname")
    end

    it "returns whether level is supported" do
      expect(@logger.debug?).to be false
      expect(@logger.info?).to be true
      expect(@logger.warn?).to be true
      expect(@logger.error?).to be true
      expect(@logger.fatal?).to be true
    end

    it "always logs unknown level errors" do
      expect(Bugsnag).to receive(:leave_breadcrumb).with(
        "message",
        "log",
        {
          :progname => "progname",
          :severity => "unknown"
        }
      )
      @logger.level = "fatal"
      @logger.add("unknown", "message", "progname")
    end

    it "allows a message to be set via block in a severity call" do
      expect(Bugsnag).to receive(:leave_breadcrumb).with(
        "block message",
        "log",
        {
          :progname => nil,
          :severity => "warn"
        }
      )
      @logger.warn {"block message"}
    end

    it "sets << messages as 'unknown" do
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

  context "a multi-logger" do
    before do
      @logger_a = double('loggera')
      @logger_b = double('loggerb')
      @multi_logger = Bugsnag::Loggers::MultiLogger.new [@logger_a, @logger_b]
    end

    it "calls each logger with a method" do
      expect(@logger_a).to receive(:close)
      expect(@logger_b).to receive(:close)
      @multi_logger.close
    end

    it "passes identical arguments through to loggers" do
      expect(@logger_a).to receive(:add).with("info", "message")
      expect(@logger_b).to receive(:add).with("info", "message")
      @multi_logger.add "info", "message"
    end

    it "returns the lowest log level it supports" do
      expect(@logger_a).to receive(:debug?).and_return(false)
      expect(@logger_b).to receive(:debug?).and_return(false)
      expect(@logger_a).to receive(:info?).and_return(false)
      expect(@logger_b).to receive(:info?).and_return(true)
      expect(@multi_logger.level?).to eq("info")
    end
  end
end

    