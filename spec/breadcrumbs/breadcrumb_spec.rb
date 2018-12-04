# encoding: utf-8

require 'spec_helper'

require 'bugsnag/breadcrumbs/breadcrumb'

describe Bugsnag::Breadcrumbs::Breadcrumb do
  describe "initialize" do
    it "should assign arguments correctly" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", "test type", {:a => 1, :b => 2}, :manual)

      expect(breadcrumb.message).to eq("my message")
      expect(breadcrumb.type).to eq("test type")
      expect(breadcrumb.meta_data).to eq({:a => 1, :b => 2})
      expect(breadcrumb.auto).to eq(:manual)

      expect(breadcrumb.timestamp).to_not be_nil
    end
  end

  describe "ignore" do
    it "should not be ignored by default" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", "test type", {:a => 1, :b => 2}, :manual)

      expect(breadcrumb.ignore?).to eq(false)
    end

    it "should be able to be ignored" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", "test type", {:a => 1, :b => 2}, :manual)
      breadcrumb.ignore!

      expect(breadcrumb.ignore?).to eq(true)
    end
  end

  describe "to_h" do
    it "should output a hash" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", "test type", {:a => 1, :b => 2}, :manual)
      output = breadcrumb.to_h

      expect(output[:message]).to eq("my message")
      expect(output[:type]).to eq("test type")
      expect(output[:metaData]).to eq({ :a => 1, :b => 2})
      expect(output[:timestamp]).to_not be_nil
    end
  end
end