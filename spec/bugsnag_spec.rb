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

    context 'with aliased at_exit' do
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

  describe "#leave_breadcrumb" do

    let(:breadcrumbs) { Bugsnag.configuration.breadcrumbs }
    let(:timestamp_regex) { /^\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:[\d\.]+Z$/ }

    it "requires only a name argument" do
      Bugsnag.leave_breadcrumb("TestName")
      expect(breadcrumbs.to_a.size).to eq(1)
      expect(breadcrumbs.first.to_h).to match({
        :name => "TestName",
        :type => Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE,
        :metaData => {},
        :timestamp => match(timestamp_regex)
      })
    end

    it "accepts meta_data" do
      Bugsnag.leave_breadcrumb("TestName", { :a => 1, :b => "2" })
      expect(breadcrumbs.to_a.size).to eq(1)
      expect(breadcrumbs.first.to_h).to match({
        :name => "TestName",
        :type => Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE,
        :metaData => { :a => 1, :b => "2" },
        :timestamp => match(timestamp_regex)
      })
    end

    it "allows different message types" do
      Bugsnag.leave_breadcrumb("TestName", {}, Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE)
      expect(breadcrumbs.to_a.size).to eq(1)
      expect(breadcrumbs.first.to_h).to match({
        :name => "TestName",
        :type => Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE,
        :metaData => {},
        :timestamp => match(timestamp_regex)
      })
    end

    it "validates before leaving" do
      Bugsnag.leave_breadcrumb(
        "123123123123123123123123123123456456456456456456456456456456",
        {
          :a => 1,
          :b => [1, 2, 3, 4],
          :c => {
            :test => true,
            :test2 => false
          }
        },
        "Not a real type"
      )
      expect(breadcrumbs.to_a.size).to eq(1)
      expect(breadcrumbs.first.to_h).to match({
        :name => "123123123123123123123123123123",
        :type => Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE,
        :metaData => {
          :a => 1
        },
        :timestamp => match(timestamp_regex)
      })
    end

    it "runs callbacks before leaving" do
      Bugsnag.configuration.before_breadcrumb_callbacks << Proc.new { |breadcrumb|
        breadcrumb.meta_data = {
          :callback => true
        }
      }
      Bugsnag.leave_breadcrumb("TestName")
      expect(breadcrumbs.to_a.size).to eq(1)
      expect(breadcrumbs.first.to_h).to match({
        :name => "TestName",
        :type => Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE,
        :metaData => {
          :callback => true
        },
        :timestamp => match(timestamp_regex)
      })
    end

    it "validates after callbacks" do
      Bugsnag.configuration.before_breadcrumb_callbacks << Proc.new { |breadcrumb|
        breadcrumb.meta_data = {
          :int => 1,
          :array => [1, 2, 3],
          :hash => {
            :a => 1,
            :b => 2
          }
        }
        breadcrumb.type = "Not a real type"
        breadcrumb.name = "123123123123123123123123123123456456456456456"
      }
      Bugsnag.leave_breadcrumb("TestName")
      expect(breadcrumbs.to_a.size).to eq(1)
      expect(breadcrumbs.first.to_h).to match({
        :name => "123123123123123123123123123123",
        :type => Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE,
        :metaData => {
          :int => 1
        },
        :timestamp => match(timestamp_regex)
      })
    end

    it "doesn't add when ignored by the validator" do
      Bugsnag.configuration.automatic_breadcrumb_types = []
      Bugsnag.leave_breadcrumb("TestName", {}, Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE, :auto)
      expect(breadcrumbs.to_a.size).to eq(0)
    end

    it "doesn't add if ignored in a callback" do
      Bugsnag.configuration.before_breadcrumb_callbacks << Proc.new { |breadcrumb|
        breadcrumb.ignore!
      }
      Bugsnag.leave_breadcrumb("TestName")
      expect(breadcrumbs.to_a.size).to eq(0)
    end

    it "doesn't add when ignored after the callbacks" do
      Bugsnag.configuration.automatic_breadcrumb_types = [
        Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE
      ]
      Bugsnag.configuration.before_breadcrumb_callbacks << Proc.new { |breadcrumb|
        breadcrumb.type = Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE
      }
      Bugsnag.leave_breadcrumb("TestName", {}, Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE, :auto)
      expect(breadcrumbs.to_a.size).to eq(0)
    end

    it "doesn't call callbacks if ignored early" do
      Bugsnag.configuration.automatic_breadcrumb_types = []
      Bugsnag.configuration.before_breadcrumb_callbacks << Proc.new { |breadcrumb|
        fail "This shouldn't be called"
      }
      Bugsnag.leave_breadcrumb("TestName", {}, Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE, :auto)
    end

    it "doesn't continue to call callbacks if ignored in them" do
      Bugsnag.configuration.before_breadcrumb_callbacks << Proc.new { |breadcrumb|
        breadcrumb.ignore!
      }
      Bugsnag.configuration.before_breadcrumb_callbacks << Proc.new { |breadcrumb|
        fail "This shouldn't be called"
      }
      Bugsnag.leave_breadcrumb("TestName")
    end
  end
end
