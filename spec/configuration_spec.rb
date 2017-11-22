# encoding: utf-8
require 'spec_helper'

describe Bugsnag::Configuration do
  describe "delivery_method" do
    it "should have the default delivery method" do
      expect(subject.delivery_method).to eq(:thread_queue)
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

  describe "add_exit_handler" do

    before do
      Bugsnag.reset_exit_handler_added
    end

    it "calls register_at_exit if true" do
      expect(Bugsnag).to receive(:register_at_exit)
      Bugsnag.configure do |conf|
        conf.api_key = "TEST KEY"
        conf.add_exit_handler = true
      end
    end

    it "doesn't call register_at_exit if false" do
      expect(Bugsnag).to_not receive(:register_at_exit)
      Bugsnag.configure do |conf|
        conf.api_key = "TEST KEY"
        conf.add_exit_handler = false
      end
    end

    it "calls at_exit when register_at_exit is called" do
      expect(Bugsnag).to receive(:at_exit)
      Bugsnag.register_at_exit
    end
  end
end
