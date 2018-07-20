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
      Bugsnag.instance_variable_set(:@exit_handler_added, false)
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

    describe 'at_exit_handler' do
      context 'with a non-signal exception' do
        it 'reports the exception' do
          exception = BugsnagTestException.new('Oh no')

          report_mock = double('report')
          expect(report_mock).to receive(:severity=).with('error')
          expect(report_mock).to receive(:severity_reason=).with({
            :type => Bugsnag::Report::UNHANDLED_EXCEPTION
          })

          expect(Bugsnag).to receive(:notify).with(exception, true).and_yield(report_mock)

          Bugsnag.at_exit_handler(exception)
        end
      end

      context 'with a signal exception' do
        it 'does not report the exception' do
          exception = SignalException.new('SIGTERM')

          expect(Bugsnag).to_not receive(:notify).with(exception, true)

          Bugsnag.at_exit_handler(exception)
        end
      end
    end

    context 'with aliased at_exit' do
      context 'and a non-signal exception' do
        before do
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

        it "calls the at_exit_handler" do
          expect(Bugsnag).to receive(:at_exit_handler)
          Bugsnag.register_at_exit
        end

        after do
          module Kernel
            alias_method :at_exit, :old_at_exit
          end
        end
      end
    end
  end

  describe 'loading integrations' do
    before do
      module Kernel
        REQUIRED = []
        alias_method :old_require, :require
        def require(path)
          if path.include?("bugsnag/integrations/")
            REQUIRED << path
          else
            old_require(path)
          end
        end
      end
    end

    it 'attempts to load integrations' do
      ENV["BUGSNAG_DISABLE_AUTOCONFIGURE"] = nil
      load "./lib/bugsnag.rb"
      Bugsnag::INTEGRATIONS.each do |integration|
        expect(Kernel::REQUIRED).to include("bugsnag/integrations/#{integration}")
      end
    end

    it 'does not load integrations when BUGSNAG_DISABLE_AUTOCONFIGURE is true' do
      ENV["BUGSNAG_DISABLE_AUTOCONFIGURE"] = 'true'
      load "./lib/bugsnag.rb"
      expect(Kernel::REQUIRED).to eq(["bugsnag/integrations/rack"])
    end

    it 'loads all integrations if requested' do
      Bugsnag.load_integrations
      Bugsnag::INTEGRATIONS.each do |integration|
        expect(Kernel::REQUIRED).to include("bugsnag/integrations/#{integration}")
      end
    end

    Bugsnag::INTEGRATIONS.each do |integration|
      it "loads #{integration}" do
        Bugsnag.load_integration(integration)
        expect(Kernel::REQUIRED).to include("bugsnag/integrations/#{integration}")
      end
    end

    it 'loads railtie for rails' do
      Bugsnag.load_integration(:rails)
      expect(Kernel::REQUIRED).to include("bugsnag/integrations/railtie")
    end

    it 'loads railtie for railtie' do
      Bugsnag.load_integration(:railtie)
      expect(Kernel::REQUIRED).to include("bugsnag/integrations/railtie")
    end

    after do
      module Kernel
        alias_method :require, :old_require
      end
      Kernel.send(:remove_const, :REQUIRED)
    end
  end
end
