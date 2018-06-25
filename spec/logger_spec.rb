# encoding: utf-8

require 'spec_helper'
require 'logger'
require 'bugsnag/breadcrumbs/logger'

describe Bugsnag::Breadcrumbs::Logger do
  let(:logger) { Bugsnag::Breadcrumbs::Logger.new }

  it "writes by default" do
    expect(Bugsnag).to receive(:leave_breadcrumb).with(
      "Log output",
      {
        :severity => "unknown",
        :message => "message"
      },
      "log"
    )
    logger << "message"
  end

  it "doesn't write when closed" do
    expect(Bugsnag).to_not receive(:leave_breadcrumb)
    logger.close
    logger << "message"
  end

  it "writes after being re-opened" do
    expect(Bugsnag).to receive(:leave_breadcrumb).with(
      "Log output",
      {
        :severity => "unknown",
        :message => "message"
      },
      "log"
    )
    logger.close
    logger.reopen
    logger << "message"
  end

  it "allows a progname and severity" do
    expect(Bugsnag).to receive(:leave_breadcrumb).with(
      "Log output",
      {
        :progname => "logTests",
        :severity => "info",
        :message => "message"
      },
      "log"
    )
    logger.info("logTests") { "message" }
  end

  it "is a logger and a bugsnag logger" do
    expect(logger.class.ancestors).to include(Bugsnag::Breadcrumbs::Logger, Logger)
  end
end
