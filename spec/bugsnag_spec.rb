# encoding: utf-8
require 'spec_helper'

describe Bugsnag do

  let(:breadcrumbs) { Bugsnag.configuration.breadcrumbs }
  let(:timestamp_regex) { /^\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:[\d\.]+Z$/ }

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

    it 'leaves a breadcrumb after exception delivery' do
      begin
        1/0
      rescue ZeroDivisionError => e
        Bugsnag.notify(e)
        sent_time = Time.now.utc
      end
      expect(breadcrumbs.to_a.size).to eq(1)
      breadcrumb = breadcrumbs.to_a.first
      expect(breadcrumb.name).to eq('ZeroDivisionError')
      expect(breadcrumb.type).to eq(Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE)
      expect(breadcrumb.auto).to eq(true)
      expect(breadcrumb.meta_data).to eq({
        :error_class => 'ZeroDivisionError',
        :message => 'divided by 0',
        :severity => 'warning'
      })
      expect(breadcrumb.timestamp).to be_within(1).of(sent_time)
    end

    it 'leave a RuntimeError breadcrumb after string delivery' do
      Bugsnag.notify('notified string')
      sent_time = Time.now.utc
      expect(breadcrumbs.to_a.size).to eq(1)
      breadcrumb = breadcrumbs.to_a.first
      expect(breadcrumb.name).to eq('RuntimeError')
      expect(breadcrumb.type).to eq(Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE)
      expect(breadcrumb.auto).to eq(true)
      expect(breadcrumb.meta_data).to eq({
        :error_class => 'RuntimeError',
        :message => 'notified string',
        :severity => 'warning'
      })
      expect(breadcrumb.timestamp).to be_within(1).of(sent_time)
    end
  end

  describe '#configure' do
    it 'calls #check_endpoint_setup every time' do
      expect(Bugsnag).to receive(:check_endpoint_setup).twice

      Bugsnag.configure
      Bugsnag.configure
    end
  end

  describe '#check_endpoint_setup' do
    let(:custom_notify_endpoint) { "Custom notify endpoint" }
    let(:custom_session_endpoint) { "Custom session endpoint" }

    it "does nothing for default endpoints or if both endpoints are set" do
      expect(Bugsnag.configuration).not_to receive(:warn)
      Bugsnag.send(:check_endpoint_setup)

      Bugsnag.configuration.set_endpoints(custom_notify_endpoint, custom_session_endpoint)
      Bugsnag.send(:check_endpoint_setup)
    end

    it "warns and disables sessions if a notify endpoint is set without a session endpoint" do
      expect(Bugsnag.configuration).to receive(:warn).with("The session endpoint has not been set, all further session capturing will be disabled")
      expect(Bugsnag.configuration).to receive(:disable_sessions)
      Bugsnag.configuration.set_endpoints(custom_notify_endpoint, nil)
      Bugsnag.send(:check_endpoint_setup)
    end

    it "raises an ArgumentError if a session endpoint is set without a notify endpoint" do
      Bugsnag.configuration.set_endpoints(nil, "custom session endpoint")
      expect{ Bugsnag.send(:check_endpoint_setup) }.to raise_error(ArgumentError, "The session endpoint cannot be modified without the notify endpoint")
    end

    it "is called after the configuration block has returned" do
      expect(Bugsnag.configuration).to receive(:warn).with("The 'endpoint' configuration option is deprecated. The 'set_endpoints' method should be used instead").once
      expect(Bugsnag.configuration).to receive(:warn).with("The 'session_endpoint' configuration option is deprecated. The 'set_endpoints' method should be used instead").once
      expect(Bugsnag.configuration).not_to receive(:warn).with("The session endpoint has not been set, all further session capturing will be disabled")
      Bugsnag.configure do |configuration|
        configuration.endpoint = custom_notify_endpoint
        configuration.session_endpoint = custom_session_endpoint
      end
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

  describe ".leave_breadcrumb" do
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
        :name => "123123123123123123123123123123456456456456456456456456456456",
        :type => Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE,
        :metaData => {
          :a => 1
        },
        :timestamp => match(timestamp_regex)
      })
    end

    it "runs callbacks before leaving" do
      Bugsnag.configuration.before_breadcrumb_callbacks << Proc.new do |breadcrumb|
        breadcrumb.meta_data = {
          :callback => true
        }
      end
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
      Bugsnag.configuration.before_breadcrumb_callbacks << Proc.new do |breadcrumb|
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
      end
      Bugsnag.leave_breadcrumb("TestName")
      expect(breadcrumbs.to_a.size).to eq(1)
      expect(breadcrumbs.first.to_h).to match({
        :name => "123123123123123123123123123123456456456456456",
        :type => Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE,
        :metaData => {
          :int => 1
        },
        :timestamp => match(timestamp_regex)
      })
    end

    it "doesn't add when ignored by the validator" do
      Bugsnag.configuration.enabled_automatic_breadcrumb_types = []
      Bugsnag.leave_breadcrumb("TestName", {}, Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE, :auto)
      expect(breadcrumbs.to_a.size).to eq(0)
    end

    it "doesn't add if ignored in a callback" do
      Bugsnag.configuration.before_breadcrumb_callbacks << Proc.new do |breadcrumb|
        breadcrumb.ignore!
      end
      Bugsnag.leave_breadcrumb("TestName")
      expect(breadcrumbs.to_a.size).to eq(0)
    end

    it "doesn't add when ignored after the callbacks" do
      Bugsnag.configuration.enabled_automatic_breadcrumb_types = [
        Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE
      ]
      Bugsnag.configuration.before_breadcrumb_callbacks << Proc.new do |breadcrumb|
        breadcrumb.type = Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE
      end
      Bugsnag.leave_breadcrumb("TestName", {}, Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE, :auto)
      expect(breadcrumbs.to_a.size).to eq(0)
    end

    it "doesn't call callbacks if ignored early" do
      Bugsnag.configuration.enabled_automatic_breadcrumb_types = []
      Bugsnag.configuration.before_breadcrumb_callbacks << Proc.new do |breadcrumb|
        fail "This shouldn't be called"
      end
      Bugsnag.leave_breadcrumb("TestName", {}, Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE, :auto)
    end

    it "doesn't continue to call callbacks if ignored in them" do
      Bugsnag.configuration.before_breadcrumb_callbacks << Proc.new do |breadcrumb|
        breadcrumb.ignore!
      end
      Bugsnag.configuration.before_breadcrumb_callbacks << Proc.new do |breadcrumb|
        fail "This shouldn't be called"
      end
      Bugsnag.leave_breadcrumb("TestName")
    end
  end

  describe "request headers" do
    it "Bugsnag-Sent-At should use the current time" do
      fake_now = Time.gm(2020, 1, 2, 3, 4, 5, 123456)
      expect(Time).to receive(:now).at_most(5).times.and_return(fake_now)

      Bugsnag.notify(BugsnagTestException.new("It crashed"))

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        # This matches the time we stubbed earlier (fake_now)
        expect(headers["Bugsnag-Sent-At"]).to eq("2020-01-02T03:04:05.123Z")
      }
    end
  end
end
