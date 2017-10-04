# encoding: utf-8

require 'spec_helper'
require 'logger'
require 'bugsnag/logging/logger'

describe Bugsnag::Logging::Logger do
  
  before do
    @logger = Bugsnag::Logging::Logger.new
  end

  it "writes by default" do
    expect(Bugsnag).to receive(:leave_breadcrumb).with(
      "message",
      "log",
      {
        :severity => "unknown"
      }
    )
    @logger << "message"
  end

  it "doesn't write when closed" do
    expect(Bugsnag).to_not receive(:leave_breadcrumb)
    @logger.close
    @logger << "message"
  end

  it "writes after being re-opened" do
    expect(Bugsnag).to receive(:leave_breadcrumb).with(
      "message",
      "log",
      {
        :severity => "unknown"
      }
    )
    @logger.close
    @logger.reopen
    @logger << "message"
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
    @logger.add Logger::INFO, "message", "logTests"
  end

  it "is a logger and a bugsnag logger" do
    expect(@logger.class.ancestors).to include(Bugsnag::Logging::Logger, Logger)
  end
end

    