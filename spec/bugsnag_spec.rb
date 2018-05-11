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
