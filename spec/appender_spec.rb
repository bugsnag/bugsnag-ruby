# encoding: utf-8

# Necessary to avoid monkey patching thread methods
ENV["LOGGING_INHERIT_CONTEXT"] = "false"

require 'spec_helper'
require 'logger'
require 'logging'
require 'bugsnag/breadcrumbs/appender'

describe Bugsnag::Breadcrumbs::Appender do
  let(:appender) { Bugsnag::Breadcrumbs::Appender.new }

  it "writes breadcrumbs" do
    expect(Bugsnag).to receive(:leave_breadcrumb).with(
      "Log output",
      {
        :severity => "unknown",
        :message => "message"
      },
      "log"
    )
    appender << "message"
  end

  it "write breadcrumbs from a logevent" do
    expect(Bugsnag).to receive(:leave_breadcrumb).with(
      "Log output",
      {
        :message => ["message1", "message2"].to_s,
        :severity => "info",
      },
      "log"
    )
    logevent = Logging::LogEvent.new("testLogger", Logger::INFO, ["message1", "message2"], false)
    appender.append logevent
  end

  it "adds trace metadata if available" do
    expect(Bugsnag).to receive(:leave_breadcrumb) do |name, metadata, severity|
      expect(name).to eq("Log output")
      expect(metadata).to include(:message, :severity, :method, :file, :line)
      expect(metadata).to include(:message => ["message1", "message2"].to_s, :severity => "info")
      expect(severity).to eq("log")
    end
    logevent = Logging::LogEvent.new("testLogger", Logger::INFO, ["message1", "message2"], true)
    appender.append logevent
  end

  it "doesn't write if closed" do
    expect(Bugsnag).to_not receive(:leave_breadcrumb)
    appender.close
    appender << "message"
    logevent = Logging::LogEvent.new("testLogger", Logger::INFO, ["message1", "message2"], false)
    appender.append logevent
  end

  it "is an appender and a bugsnag appender" do
    expect(appender.class.ancestors).to include(Bugsnag::Breadcrumbs::Appender, Logging::Appender)
  end
end
