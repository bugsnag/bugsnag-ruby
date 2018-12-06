# encoding: utf-8

require 'spec_helper'

require 'bugsnag/breadcrumbs/breadcrumb'

RSpec.describe Bugsnag::Breadcrumbs::Breadcrumb do
  describe "#name" do
    it "is assigned in #initialize" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", nil, nil, nil)

      expect(breadcrumb.name).to eq("my message")
    end
  end

  describe "#type" do
    it "is assigned in #initialize" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(nil, "test type", nil, nil)

      expect(breadcrumb.type).to eq("test type")
    end
  end

  describe "#meta_data" do
    it "is assigned in #initialize" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(nil, nil, {:a => 1, :b => 2}, nil)

      expect(breadcrumb.meta_data).to eq({:a => 1, :b => 2})
    end
  end

  describe "#auto" do
    it "defaults to false" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(nil, nil, nil, nil)

      expect(breadcrumb.auto).to eq(false)
    end

    it "is true if auto argument == :auto" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(nil, nil, nil, :auto)

      expect(breadcrumb.auto).to eq(true)
    end

    it "is false if auto argument is anything else" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(nil, nil, nil, :manual)

      expect(breadcrumb.auto).to eq(false)
    end
  end

  describe "#timestamp" do
    it "is stored as a timestamp" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(nil, nil, nil, nil)

      expect(breadcrumb.timestamp).to be_within(0.5).of Time.now.utc
    end
  end

  describe "#ignore?" do
    it "is not true by default" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", "test type", {:a => 1, :b => 2}, :manual)

      expect(breadcrumb.ignore?).to eq(false)
    end

    it "is able to be set" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", "test type", {:a => 1, :b => 2}, :manual)
      breadcrumb.ignore!

      expect(breadcrumb.ignore?).to eq(true)
    end
  end

  describe "#to_h" do
    it "outputs as a hash" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", "test type", {:a => 1, :b => 2}, :manual)
      output = breadcrumb.to_h

      timestamp_regex = /^\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:[\d\.]+Z$/

      expect(output).to match(
        :name => "my message",
        :type => "test type",
        :metaData => {
          :a => 1,
          :b => 2
        },
        :timestamp => eq(breadcrumb.timestamp.iso8601)
      )
    end
  end
end