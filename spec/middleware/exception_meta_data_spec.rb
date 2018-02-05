# encoding: utf-8
require 'spec_helper'

describe Bugsnag::Middleware::ExceptionMetaData do
  let(:report_class) do
    Class.new do
      attr_accessor :raw_exceptions, :tabs, :user, :context, :grouping_hash

      def initialize(errors)
        self.raw_exceptions = Array(errors)
      end

      def add_tab(key, value)
        self.tabs ||= {}
        tabs[key] = value
      end
    end
  end

  let(:middleware) { Bugsnag::Middleware::ExceptionMetaData.new(lambda {|_|}) }
  let(:bugsnag_error_class) { Class.new(StandardError) { include Bugsnag::MetaData } }

  it "adds metadata when exception singleton class extended with Bugsnag::MetaData" do
    error = RuntimeError.new
    error.extend(Bugsnag::MetaData)
    error.bugsnag_meta_data = {"foo" => "bar"}

    report = report_class.new(error)

    middleware.call(report)

    expect(report.tabs).to eq({"foo" => "bar"})
  end

  it "adds metadata when exception class includes Bugsnag::MetaData" do
    error = bugsnag_error_class.new
    error.bugsnag_meta_data = {"foo" => "bar"}

    report = report_class.new(error)

    middleware.call(report)

    expect(report.tabs).to eq({"foo" => "bar"})
  end

  it "sets user ID when a string" do
    error = bugsnag_error_class.new
    error.bugsnag_user_id = "1234"

    report = report_class.new(error)

    middleware.call(report)

    expect(report.user).to eq({id: "1234"})
  end

  it "sets context when a string" do
    error = bugsnag_error_class.new
    error.bugsnag_context = "Foo#bar"

    report = report_class.new(error)

    middleware.call(report)

    expect(report.context).to eq("Foo#bar")
  end

  it "sets grouping_hash when a string" do
    error = bugsnag_error_class.new
    error.bugsnag_grouping_hash = "abcdef"

    report = report_class.new(error)

    middleware.call(report)

    expect(report.grouping_hash).to eq("abcdef")
  end

  it "does nothing when no bugsnag attributes are set" do
    error = bugsnag_error_class.new
    report = report_class.new(error)

    middleware.call(report)

    expect(report.user).to eq(nil)
    expect(report.tabs).to eq(nil)
    expect(report.grouping_hash).to eq(nil)
    expect(report.context).to eq(nil)
  end
end
