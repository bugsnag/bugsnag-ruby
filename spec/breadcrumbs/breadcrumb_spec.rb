# encoding: utf-8

require 'spec_helper'

require 'bugsnag/breadcrumbs/breadcrumb'

describe Bugsnag::Breadcrumbs::Breadcrumb do
  describe "#message" do
    it "is assigned in #initialize" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", nil, nil, nil)

      expect(breadcrumb.message).to eq("my message")
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

    it "if false if auto argument is anything else" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(nil, nil, nil, :manual)

      expect(breadcrumb.auto).to eq(false)
    end
  end

  describe "#timestamp" do
    it "is stored as a timestamp" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(nil, nil, nil, nil)

      expect(breadcrumb.timestamp).to be_within(0.5.second).of Time.now
    end
  end

  describe "#ignore" do
    it "is not ignored by default" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", "test type", {:a => 1, :b => 2}, :manual)

      expect(breadcrumb.ignore?).to eq(false)
    end

    it "is able to be ignored" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", "test type", {:a => 1, :b => 2}, :manual)
      breadcrumb.ignore!

      expect(breadcrumb.ignore?).to eq(true)
    end
  end

  describe "#to_h" do
    it "outputs as a hash" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", "test type", {:a => 1, :b => 2}, :manual)
      output = breadcrumb.to_h

      expect(output[:name]).to eq("my message")
      expect(output[:type]).to eq("test type")
      expect(output[:metaData]).to eq({ :a => 1, :b => 2})

      timestamp_regex = /^\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:[\d\.]+Z$/

      expect(output[:timestamp]).to be_a_kind_of(String)
      expect(output[:timestamp]).to match(timestamp_regex)
    end
  end
end