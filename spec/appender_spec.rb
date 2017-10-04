# encoding: utf-8

require 'spec_helper'
require 'logger'
require 'logging'
require 'bugsnag/logging/appender'

describe Bugsnag::Logging::Appender do
  
  before do
    @appender = Bugsnag::Logging::Appender.new
  end

  it "writes breadcrumbs" do
    expect(Bugsnag).to receive(:leave_breadcrumb).with(
      "message",
      "log",
      {
        :severity => "unknown"
      }
    )
    @appender << "message"
  end

  it "write breadcrumbs from a logevent" do
    expect(Bugsnag).to receive(:leave_breadcrumb).with(
      "testLogger",
      "log",
      {
        :data => ["message1", "message2"],
        :severity => "info"
      }
    )
    logevent = Logging::LogEvent.new("testLogger", Logger::INFO, ["message1", "message2"], false)
    @appender.append logevent
  end

  it "adds trace metadata if available" do
    expect(Bugsnag).to receive(:leave_breadcrumb).with(
      "testLogger",
      "log",
      {
        :trace => hash_including(:method, :file, :line),
        :data => ["message1", "message2"],
        :severity => "info"
      }
    )
    logevent = Logging::LogEvent.new("testLogger", Logger::INFO, ["message1", "message2"], true)
    @appender.append logevent
  end

  it "doesn't write if closed" do
    expect(Bugsnag).to_not receive(:leave_breadcrumb)
    @appender.close
    @appender << "message"
    logevent = Logging::LogEvent.new("testLogger", Logger::INFO, ["message1", "message2"], false)
    @appender.append logevent
  end

  it "is an appender and a bugsnag appender" do
    expect(@appender.class.ancestors).to include(Bugsnag::Logging::Appender, Logging::Appender)
  end
end

    