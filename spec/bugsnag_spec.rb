# encoding: utf-8
require 'spec_helper'

describe Bugsnag do
  describe 'notify' do
    before do
      Bugsnag.configuration.logger = spy('logger')
    end

    it 'does not log an error when sending valid arguments as auto_notify' do
      notify_test_exception(true)
      expect(Bugsnag.configuration.logger).to_not have_received(:warn)
    end
    it 'logs an error when sending invalid arguments as auto_notify' do
      notify_test_exception({severity: 'info'})
      expect(Bugsnag.configuration.logger).to have_received(:warn)
    end
  end

  describe "add_exit_handler" do

    before do
      Bugsnag.reset_exit_handler_added
      module Kernel
        alias_method :old_at_exit, :at_exit
        def at_exit
          begin
            raise BugsnagTestException.new("Oh no")
          rescue
            yield
          end
        end
      end
    end

    it "automatically adds an exit handler" do
      expect(Bugsnag).to receive(:register_at_exit)
      Bugsnag.configure do |conf|
        conf.api_key = "TEST KEY"
      end
    end

    it "calls at_exit when register_at_exit is called" do
      expect(Bugsnag).to receive(:at_exit)
      Bugsnag.register_at_exit
    end

    it "doesn't call at_exit on subsequent calls" do
      expect(Bugsnag).to receive(:at_exit).once
      Bugsnag.register_at_exit
      Bugsnag.register_at_exit
    end

    it "sends an exception when at_exit is called" do
      report_mock = double('report')
      expect(report_mock).to receive(:severity=).with('error')
      expect(report_mock).to receive(:severity_reason=).with({
        :type => Bugsnag::Report::UNHANDLED_EXCEPTION
      })
      expect(Bugsnag).to receive(:notify).with(kind_of(BugsnagTestException), true).and_yield(report_mock)
      Bugsnag.register_at_exit
    end

    after do
      module Kernel
        alias_method :at_exit, :old_at_exit
      end
    end

  end
end
