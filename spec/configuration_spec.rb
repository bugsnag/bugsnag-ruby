# encoding: utf-8
require 'spec_helper'

describe Bugsnag::Configuration do
  describe "delivery_method" do
    it "should have the default delivery method" do
      expect(subject.delivery_method).to eq(Bugsnag::Configuration::DEFAULT_DELIVERY_METHOD)
    end

    it "should have the defined delivery_method" do
      subject.delivery_method = :test
      expect(subject.delivery_method).to eq(:test)
    end

    it "should allow a new default delivery_method to be set" do
      subject.default_delivery_method = :test
      expect(subject.delivery_method).to eq(:test)
    end

    it "should allow the delivery_method to be set over a default" do
      subject.default_delivery_method = :test
      subject.delivery_method = :wow
      expect(subject.delivery_method).to eq(:wow)
    end
  end
end
