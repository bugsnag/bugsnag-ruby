# encoding: utf-8
require 'spec_helper'
require 'support/shared_examples_for_metadata'

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

    it 'can deliver when an error raised in the block argument' do
      Bugsnag.notify(RuntimeError.new('Manual notify notified even though it raised')) do |report|
        raise 'This is the error message'
      end

      expected_messages = [
        /^Error in notify block: This is the error message$/,
        /^Error in notify block stacktrace: \[/
      ].each

      expect(Bugsnag.configuration.logger).to have_received(:warn).with('[Bugsnag]').twice do |&block|
        expect(block.call).to match(expected_messages.next)
      end

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        event = get_event_from_payload(payload)
        expect(event['exceptions'].first['message']).to eq('Manual notify notified even though it raised')
      }
    end

    it 'can deliver when an error raised in the block argument and auto_notify is true' do
      Bugsnag.notify(RuntimeError.new('Auto notify notified even though it raised'), true) do |report|
        raise 'This is an auto_notify error'
      end

      expected_messages = [
        /^Error in internal notify block: This is an auto_notify error$/,
        /^Error in internal notify block stacktrace: \[/
      ].each

      expect(Bugsnag.configuration.logger).to have_received(:warn).with('[Bugsnag]').twice do |&block|
        expect(block.call).to match(expected_messages.next)
      end

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        event = get_event_from_payload(payload)
        expect(event['exceptions'].first['message']).to eq('Auto notify notified even though it raised')
      }
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
      expect(Bugsnag.configuration).to receive(:warn).with(Bugsnag::EndpointValidator::Result::MISSING_SESSION_URL)
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
      expect(Bugsnag.configuration).to receive(:warn).with("The 'endpoint' configuration option is deprecated. Set both endpoints with the 'endpoints=' method instead").once
      expect(Bugsnag.configuration).to receive(:warn).with("The 'session_endpoint' configuration option is deprecated. Set both endpoints with the 'endpoints=' method instead").once
      expect(Bugsnag.configuration).not_to receive(:warn).with("The session endpoint has not been set, all further session capturing will be disabled")

      Bugsnag.configure do |configuration|
        configuration.endpoint = custom_notify_endpoint
        configuration.session_endpoint = custom_session_endpoint
      end
    end
  end

  describe "endpoint configuration" do
    it "does not send events when both endpoints are invalid" do
      Bugsnag.configuration.endpoints = {}

      expect(Bugsnag.configuration).not_to receive(:debug)
      expect(Bugsnag.configuration).not_to receive(:info)
      expect(Bugsnag.configuration).not_to receive(:warn)
      expect(Bugsnag.configuration).not_to receive(:error)

      Bugsnag.notify(RuntimeError.new("abc"))

      expect(Bugsnag).not_to have_sent_notification
    end

    it "does not send sessions when both endpoints are invalid" do
      Bugsnag.configuration.endpoints = {}

      expect(Bugsnag.configuration).not_to receive(:debug)
      expect(Bugsnag.configuration).not_to receive(:info)
      expect(Bugsnag.configuration).not_to receive(:warn)
      expect(Bugsnag.configuration).not_to receive(:error)

      Bugsnag.start_session

      expect(Bugsnag).not_to have_sent_sessions
    end

    it "does not send events or sessions when the notify endpoint is invalid" do
      Bugsnag.configuration.endpoints = { sessions: "sessions.example.com" }

      expect(Bugsnag.configuration).not_to receive(:debug)
      expect(Bugsnag.configuration).not_to receive(:info)
      expect(Bugsnag.configuration).not_to receive(:warn)
      expect(Bugsnag.configuration).not_to receive(:error)

      Bugsnag.notify(RuntimeError.new("abc"))
      Bugsnag.start_session

      expect(Bugsnag).not_to have_sent_notification
      expect(Bugsnag).not_to have_sent_sessions
    end

    it "does not send sessions when the session endpoint is invalid" do
      Bugsnag.configuration.endpoints = Bugsnag::EndpointConfiguration.new("http://notify.example.com", nil)

      expect(Bugsnag.configuration).to receive(:debug).with("Request to http://notify.example.com completed, status: 200").once
      expect(Bugsnag.configuration).to receive(:info).with("Notifying http://notify.example.com of RuntimeError").once
      expect(Bugsnag.configuration).not_to receive(:warn)
      expect(Bugsnag.configuration).not_to receive(:error)

      stub_request(:post, "http://notify.example.com/")

      Bugsnag.notify(RuntimeError.new("abc"))
      Bugsnag.start_session

      expect(Bugsnag).to(have_requested(:post, "http://notify.example.com/").with do |request|
        payload = JSON.parse(request.body)
        exception = get_exception_from_payload(payload)

        expect(exception["message"]).to eq("abc")
      end)

      expect(Bugsnag).not_to have_sent_sessions
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
          :a => 1,
          :b => [1, 2, 3, 4],
          :c => {
            :test => true,
            :test2 => false
          }
        },
        :timestamp => match(timestamp_regex)
      })
    end

    describe "before_breadcrumb_callbacks" do
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
            :int => 1,
            :array => [1, 2, 3],
            :hash => {
              :a => 1,
              :b => 2
            }
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

    describe "on_breadcrumb callbacks" do
      it "runs callbacks when a breadcrumb is left" do
        Bugsnag.add_on_breadcrumb(proc do |breadcrumb|
          breadcrumb.metadata = { callback: true }
        end)

        Bugsnag.leave_breadcrumb("TestName")

        expect(breadcrumbs.to_a.size).to eq(1)
        expect(breadcrumbs.first.to_h).to match({
          name: "TestName",
          type: Bugsnag::BreadcrumbType::MANUAL,
          metaData: { callback: true },
          timestamp: match(timestamp_regex)
        })
      end

      it "validates any changes made in a callback" do
        Bugsnag.add_on_breadcrumb(proc do |breadcrumb|
          breadcrumb.metadata = { abc: 123, xyz: { a: 1, b: 2 } }

          breadcrumb.type = "Not a real type"
          breadcrumb.name = "123123123123123123123123123123456456456456456"
        end)

        Bugsnag.leave_breadcrumb("TestName")

        expect(breadcrumbs.to_a.size).to eq(1)
        expect(breadcrumbs.first.to_h).to match({
          name: "123123123123123123123123123123456456456456456",
          type: Bugsnag::BreadcrumbType::MANUAL,
          metaData: { abc: 123, xyz: { a: 1, b: 2 } },
          timestamp: match(timestamp_regex)
        })
      end

      it "doesn't add the breadcrumb when ignored due to enabled_breadcrumb_types" do
        Bugsnag.configure do |config|
          config.enabled_breadcrumb_types = [Bugsnag::BreadcrumbType::MANUAL]

          config.add_on_breadcrumb(proc do |breadcrumb|
            breadcrumb.type = Bugsnag::BreadcrumbType::ERROR
          end)
        end

        Bugsnag.leave_breadcrumb("TestName", {}, Bugsnag::BreadcrumbType::MANUAL, :auto)

        expect(breadcrumbs.to_a).to be_empty
      end

      it "stops calling callbacks if the breadcrumb is ignored in them" do
        callback1 = spy('callback1')
        callback2 = spy('callback2')

        Bugsnag.configure do |config|
          config.add_on_breadcrumb(callback1)
          config.add_on_breadcrumb(proc { false })
          config.add_on_breadcrumb(callback2)
        end

        Bugsnag.leave_breadcrumb("TestName", {}, Bugsnag::BreadcrumbType::ERROR, :auto)

        expect(callback1).to have_received(:call)
        expect(callback2).not_to have_received(:call)
      end

      it "continues calling callbacks after a callback raises" do
        callback1 = spy('callback1')
        callback2 = spy('callback2')

        Bugsnag.configure do |config|
          config.add_on_breadcrumb(callback1)
          config.add_on_breadcrumb(proc { raise 'uh oh' })
          config.add_on_breadcrumb(callback2)
        end

        Bugsnag.leave_breadcrumb("TestName", {}, Bugsnag::BreadcrumbType::ERROR, :auto)

        expect(callback1).to have_received(:call)
        expect(callback2).to have_received(:call)
        expect(breadcrumbs.to_a.first.to_h).to match({
          name: "TestName",
          type: Bugsnag::BreadcrumbType::ERROR,
          metaData: {},
          timestamp: match(timestamp_regex)
        })
      end
    end
  end

  describe "request headers" do
    it "Bugsnag-Sent-At should use the current time" do
      fake_now = Time.gm(2020, 1, 2, 3, 4, 5, 123456)
      expect(Time).to receive(:now).at_most(6).times.and_return(fake_now)

      Bugsnag.notify(BugsnagTestException.new("It crashed"))

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        # This matches the time we stubbed earlier (fake_now)
        expect(headers["Bugsnag-Sent-At"]).to eq("2020-01-02T03:04:05.123Z")
      }
    end
  end

  describe "#breadcrumbs" do
    it "returns the configuration's breadcrumb buffer" do
      expect(Bugsnag.breadcrumbs).to be(Bugsnag.configuration.breadcrumbs)
    end
  end

  describe "sessions" do
    let(:session_id_regex) { /\A[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}\z/ }
    let(:session_timestamp_regex) { /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:00\z/ }

    it "attaches session information for handled errors" do
      Bugsnag.configure do |config|
        config.auto_capture_sessions = true
      end

      Bugsnag.start_session
      Bugsnag.notify(BugsnagTestException.new("It crashed"))

      expect(Bugsnag).to(have_sent_notification { |payload, headers|
        session = payload["events"][0]["session"]

        expect(session["id"]).to match(session_id_regex)
        expect(session["startedAt"]).to match(session_timestamp_regex)
        expect(session["events"]).to eq({
          "handled" => 1,
          "unhandled" => 0,
        })

        expect(Bugsnag::SessionTracker.get_current_session[:events]).to eq({
          handled: 1,
          unhandled: 0,
        })
      })
    end

    it "attaches session information for unhandled errors" do
      Bugsnag.configure do |config|
        config.auto_capture_sessions = true
      end

      Bugsnag.start_session
      Bugsnag.notify(BugsnagTestException.new("It crashed"), true)

      expect(Bugsnag).to(have_sent_notification { |payload, headers|
        session = payload["events"][0]["session"]

        expect(session["id"]).to match(session_id_regex)
        expect(session["startedAt"]).to match(session_timestamp_regex)
        expect(session["events"]).to eq({
          "handled" => 0,
          "unhandled" => 1,
        })

        expect(Bugsnag::SessionTracker.get_current_session[:events]).to eq({
          handled: 0,
          unhandled: 1,
        })
      })
    end

    it "attaches session information for multiple errors" do
      Bugsnag.configure do |config|
        config.auto_capture_sessions = true
      end

      Bugsnag.start_session

      Bugsnag.notify(BugsnagTestException.new("one handled"))
      Bugsnag.notify(BugsnagTestException.new("one unhandled"), true)
      Bugsnag.notify(BugsnagTestException.new("two handled"))

      # reset WebMock's stored requests so we only assert against the last one
      # as "have_sent_notification" doesn't support finding a specific request
      WebMock::RequestRegistry.instance.reset!

      Bugsnag.notify(BugsnagTestException.new("two unhandled"), true)

      expect(Bugsnag).to(have_sent_notification { |payload, headers|
        session = payload["events"][0]["session"]

        expect(session["id"]).to match(session_id_regex)
        expect(session["startedAt"]).to match(session_timestamp_regex)
        expect(session["events"]).to eq({
          "handled" => 2,
          "unhandled" => 2,
        })

        expect(Bugsnag::SessionTracker.get_current_session[:events]).to eq({
          handled: 2,
          unhandled: 2,
        })
      })
    end

    it "does not attach session information when the session is paused" do
      Bugsnag.configure do |config|
        config.auto_capture_sessions = true
      end

      Bugsnag.start_session
      Bugsnag.pause_session

      Bugsnag.notify(BugsnagTestException.new("It crashed"), true)

      expect(Bugsnag).to(have_sent_notification { |payload, headers|
        expect(payload["events"][0]["session"]).to be(nil)

        expect(Bugsnag::SessionTracker.get_current_session[:events]).to eq({
          handled: 0,
          unhandled: 0,
        })
      })
    end

    it "attaches session information when the session is resumed" do
      Bugsnag.configure do |config|
        config.auto_capture_sessions = true
      end

      Bugsnag.start_session

      Bugsnag.notify(BugsnagTestException.new("one handled"))

      Bugsnag.pause_session

      Bugsnag.notify(BugsnagTestException.new("this unhandled error is not counted"), true)
      Bugsnag.notify(BugsnagTestException.new("this handled error is not counted"))

      # reset WebMock's stored requests so we only assert against the last one
      # as "have_sent_notification" doesn't support finding a specific request
      WebMock::RequestRegistry.instance.reset!

      Bugsnag.resume_session

      Bugsnag.notify(BugsnagTestException.new("one unhandled"), true)

      expect(Bugsnag).to(have_sent_notification { |payload, headers|
        session = payload["events"][0]["session"]

        expect(session["id"]).to match(session_id_regex)
        expect(session["startedAt"]).to match(session_timestamp_regex)
        expect(session["events"]).to eq({
          "handled" => 1,
          "unhandled" => 1,
        })

        expect(Bugsnag::SessionTracker.get_current_session[:events]).to eq({
          handled: 1,
          unhandled: 1,
        })
      })
    end

    it "allows changing an event from handled to unhandled" do
      Bugsnag.configure do |config|
        config.auto_capture_sessions = true
      end

      Bugsnag.start_session
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
        expect(report.session[:events]).to eq({ handled: 1, unhandled: 0 })

        report.unhandled = true

        expect(report.session[:events]).to eq({ handled: 0, unhandled: 1 })
      end

      expect(Bugsnag).to(have_sent_notification { |payload, headers|
        event = payload["events"].first

        expect(event["unhandled"]).to be(true)
        expect(event["severityReason"]).to eq({
          "type" => "handledException",
          "unhandledOverridden" => true
        })

        session = event["session"]

        expect(session["id"]).to match(session_id_regex)
        expect(session["startedAt"]).to match(session_timestamp_regex)
        expect(session["events"]).to eq({
          "handled" => 0,
          "unhandled" => 1,
        })

        expect(Bugsnag::SessionTracker.get_current_session[:events]).to eq({
          handled: 0,
          unhandled: 1,
        })
      })
    end

    it "allows changing an event from unhandled to handled" do
      Bugsnag.configure do |config|
        config.auto_capture_sessions = true

        # we have to use an on_error here because blocks are evaluated before we
        # store the initial unhandled-ness for unhandled notify calls
        config.add_on_error(proc do |report|
          expect(report.session[:events]).to eq({ handled: 0, unhandled: 1 })

          report.unhandled = false

          expect(report.session[:events]).to eq({ handled: 1, unhandled: 0 })
        end)
      end

      Bugsnag.start_session
      Bugsnag.notify(BugsnagTestException.new("It crashed"), true)

      expect(Bugsnag).to(have_sent_notification { |payload, headers|
        event = payload["events"].first

        expect(event["unhandled"]).to be(false)
        expect(event["severityReason"]).to eq({
          "type" => "unhandledException",
          "unhandledOverridden" => true
        })

        session = event["session"]

        expect(session["id"]).to match(session_id_regex)
        expect(session["startedAt"]).to match(session_timestamp_regex)
        expect(session["events"]).to eq({
          "handled" => 1,
          "unhandled" => 0,
        })

        expect(Bugsnag::SessionTracker.get_current_session[:events]).to eq({
          handled: 1,
          unhandled: 0,
        })
      })
    end

    it "allows changing an event from handled to unhandled and back again" do
      Bugsnag.configure do |config|
        config.auto_capture_sessions = true

        config.add_on_error(proc do |report|
          expect(report.session[:events]).to eq({ handled: 1, unhandled: 0 })

          report.unhandled = !report.unhandled

          expect(report.session[:events]).to eq({ handled: 0, unhandled: 1 })
        end)

        config.add_on_error(proc do |report|
          expect(report.session[:events]).to eq({ handled: 0, unhandled: 1 })

          report.unhandled = !report.unhandled

          expect(report.session[:events]).to eq({ handled: 1, unhandled: 0 })
        end)
      end

      Bugsnag.start_session
      Bugsnag.notify(BugsnagTestException.new("It crashed"))

      expect(Bugsnag).to(have_sent_notification { |payload, headers|
        event = payload["events"].first

        expect(event["unhandled"]).to be(false)
        expect(event["severityReason"]).to eq({ "type" => "handledException" })

        session = event["session"]

        expect(session["id"]).to match(session_id_regex)
        expect(session["startedAt"]).to match(session_timestamp_regex)
        expect(session["events"]).to eq({
          "handled" => 1,
          "unhandled" => 0,
        })

        expect(Bugsnag::SessionTracker.get_current_session[:events]).to eq({
          handled: 1,
          unhandled: 0,
        })
      })
    end

    it "allows changing an event from unhandled to handled and back again" do
      Bugsnag.configure do |config|
        config.auto_capture_sessions = true

        config.add_on_error(proc do |report|
          expect(report.session[:events]).to eq({ handled: 0, unhandled: 1 })

          report.unhandled = false

          expect(report.session[:events]).to eq({ handled: 1, unhandled: 0 })
        end)

        config.add_on_error(proc do |report|
          expect(report.session[:events]).to eq({ handled: 1, unhandled: 0 })

          report.unhandled = true

          expect(report.session[:events]).to eq({ handled: 0, unhandled: 1 })
        end)
      end

      Bugsnag.start_session
      Bugsnag.notify(BugsnagTestException.new("It crashed"), true)

      expect(Bugsnag).to(have_sent_notification { |payload, headers|
        event = payload["events"].first

        expect(event["unhandled"]).to be(true)
        expect(event["severityReason"]).to eq({ "type" => "unhandledException" })

        session = event["session"]

        expect(session["id"]).to match(session_id_regex)
        expect(session["startedAt"]).to match(session_timestamp_regex)
        expect(session["events"]).to eq({
          "handled" => 0,
          "unhandled" => 1,
        })

        expect(Bugsnag::SessionTracker.get_current_session[:events]).to eq({
          handled: 0,
          unhandled: 1,
        })
      })
    end

    it "works for handled -> unhandled errors if a session is started during notify" do
      Bugsnag.configure do |config|
        config.auto_capture_sessions = true
        config.add_on_error(proc { Bugsnag.start_session })
      end

      Bugsnag.start_session

      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
        expect(report.session[:events]).to eq({ handled: 1, unhandled: 0 })

        report.unhandled = true

        expect(report.session[:events]).to eq({ handled: 0, unhandled: 1 })
      end

      expect(Bugsnag).to(have_sent_notification { |payload, headers|
        event = payload["events"].first

        expect(event["unhandled"]).to be(true)
        expect(event["severityReason"]).to eq({
          "type" => "handledException",
          "unhandledOverridden" => true
        })

        session = event["session"]

        expect(session["id"]).to match(session_id_regex)
        expect(session["startedAt"]).to match(session_timestamp_regex)
        expect(session["events"]).to eq({
          "handled" => 0,
          "unhandled" => 1,
        })

        # the new session was started _after_ the error was notified, so should
        # have 0 events
        expect(Bugsnag::SessionTracker.get_current_session[:events]).to eq({
          handled: 0,
          unhandled: 0,
        })
      })
    end

    it "works for unhandled -> handled errors if a session is started during notify" do
      Bugsnag.configure do |config|
        config.auto_capture_sessions = true
        config.add_on_error(proc do |report|
          expect(report.session[:events]).to eq({ handled: 0, unhandled: 1 })

          report.unhandled = false

          expect(report.session[:events]).to eq({ handled: 1, unhandled: 0 })
        end)

        config.add_on_error(proc { Bugsnag.start_session })
      end

      Bugsnag.start_session

      Bugsnag.notify(BugsnagTestException.new("It crashed"), true)

      expect(Bugsnag).to(have_sent_notification { |payload, headers|
        event = payload["events"].first

        expect(event["unhandled"]).to be(false)
        expect(event["severityReason"]).to eq({
          "type" => "unhandledException",
          "unhandledOverridden" => true
        })

        session = event["session"]

        expect(session["id"]).to match(session_id_regex)
        expect(session["startedAt"]).to match(session_timestamp_regex)
        expect(session["events"]).to eq({
          "handled" => 1,
          "unhandled" => 0,
        })

        # the new session was started _after_ the error was notified, so should
        # have 0 events
        expect(Bugsnag::SessionTracker.get_current_session[:events]).to eq({
          handled: 0,
          unhandled: 0,
        })
      })
    end

    it "works for multiple errors if a session is started during notify" do
      Bugsnag.configure do |config|
        config.auto_capture_sessions = true

        config.add_on_error(proc do |report|
          # start a new session when notifying the second error so that there
          # are two errors with the first session and two with the new session
          if report.errors.first.error_message == "one unhandled"
            Bugsnag.start_session
          end
        end)
      end

      Bugsnag.start_session

      Bugsnag.notify(BugsnagTestException.new("one handled"))
      Bugsnag.notify(BugsnagTestException.new("one unhandled"), true)
      Bugsnag.notify(BugsnagTestException.new("two handled"))

      # reset WebMock's stored requests so we only assert against the last one
      # as "have_sent_notification" doesn't support finding a specific request
      WebMock::RequestRegistry.instance.reset!

      Bugsnag.notify(BugsnagTestException.new("two unhandled"), true)

      expect(Bugsnag).to(have_sent_notification { |payload, headers|
        session = payload["events"][0]["session"]

        expect(session["id"]).to match(session_id_regex)
        expect(session["startedAt"]).to match(session_timestamp_regex)
        expect(session["events"]).to eq({
          "handled" => 1,
          "unhandled" => 1,
        })

        expect(Bugsnag::SessionTracker.get_current_session[:events]).to eq({
          handled: 1,
          unhandled: 1,
        })
      })
    end
  end

  describe "global metadata" do
    include_examples(
      "metadata delegate",
      lambda do |metadata, *args|
        Bugsnag.configuration.instance_variable_set(:@metadata, metadata)

        Bugsnag.add_metadata(*args)
      end,
      lambda do |metadata, *args|
        Bugsnag.configuration.instance_variable_set(:@metadata, metadata)

        Bugsnag.clear_metadata(*args)
      end
    )

    describe "#metadata" do
      it "is initially empty" do
        expect(subject.metadata).to be_empty
      end

      it "cannot be reassigned" do
        expect(subject).not_to respond_to(:metadata=)
      end

      it "reflects changes made by add_/clear_metadata" do
        subject.add_metadata(:abc, { a: 1, b: 2, c: 3 })
        subject.add_metadata(:xyz, :x, 1)

        expect(subject.metadata).to eq({ abc: { a: 1, b: 2, c: 3 }, xyz: { x: 1 } })

        subject.clear_metadata(:abc)

        expect(subject.metadata).to eq({ xyz: { x: 1 } })
      end
    end

    it "is added to the payload" do
      Bugsnag.add_metadata(:abc, { a: 1, b: 2, c: 3 })
      Bugsnag.add_metadata(:xyz, { x: 1, y: 2, z: 3 })
      Bugsnag.add_metadata(:example, { array: [1, 2, 3], string: "hello" })

      Bugsnag.notify(RuntimeError.new("example")) do |report|
        report.add_metadata(:abc, :d, 4)
        report.metadata[:example][:array].push(4, 5, 6)
        report.metadata[:example][:string].upcase!

        report.clear_metadata(:abc, :b)
        report.clear_metadata(:xyz, :z)
        Bugsnag.clear_metadata(:abc)

        expect(report.metadata).to eq({
          abc: { a: 1, c: 3, d: 4 },
          xyz: { x: 1, y: 2 },
          example: { array: [1, 2, 3, 4, 5, 6], string: "HELLO" },
        })

        expect(Bugsnag.metadata).to eq({
          xyz: { x: 1, y: 2, z: 3 },
          example: { array: [1, 2, 3], string: "hello" },
        })
      end

      expect(Bugsnag).to(have_sent_notification { |payload, headers|
        event = get_event_from_payload(payload)

        expect(event["metaData"]).to eq({
          "abc" => { "a" => 1, "c" => 3, "d" => 4 },
          "xyz" => { "x" => 1, "y" => 2 },
          "example" => { "array" => [1, 2, 3, 4, 5, 6], "string" => "HELLO" },
        })

        expect(Bugsnag.metadata).to eq({
          xyz: { x: 1, y: 2, z: 3 },
          example: { array: [1, 2, 3], string: "hello" },
        })
      })
    end
  end
end
