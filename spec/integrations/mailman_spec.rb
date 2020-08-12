require "spec_helper"

describe 'Bugsnag::Mailman', :order => :defined do
  before do
    unless defined?(::Mailman)
      @mocked_mailman = true
      class Mailman
        VERSION = '9.8.7'
      end
      module Kernel
        alias_method :old_require, :require
        def require(path)
          old_require(path) unless /^mailman/.match(path)
        end
      end
    end
  end

  it "should load Bugsnag::Mailman" do
    config = double('mailman-config')
    allow(Mailman).to receive(:config).and_return(config)
    expect(config).to receive(:respond_to?).with(:middleware).and_return(true)
    middleware = spy('mailman-config-middleware')
    expect(config).to receive(:middleware).and_return(middleware)

    # Kick off
    require './lib/bugsnag/integrations/mailman'

    expect(middleware).to have_received(:add).with(Bugsnag::Mailman)
  end

  it "can be called" do
    integration = Bugsnag::Mailman.new

    # Initialising the middleware should set some config options
    expect(Bugsnag.configuration.internal_middleware.last).to eq(Bugsnag::Middleware::Mailman)
    expect(Bugsnag.configuration.app_type).to eq('mailman')
    expect(Bugsnag.configuration.runtime_versions['mailman']).to eq(Mailman::VERSION)

    mail = 'To: My Friend; From: Your Pal; Subject: Hello!'
    exception = RuntimeError.new('oops')

    expect { integration.call(mail) { raise exception } }.to raise_error(exception)

    expect(Bugsnag).to have_sent_notification { |payload, headers|
      event = get_event_from_payload(payload)

      expect(event['unhandled']).to be(true)
      expect(event['severity']).to eq('error')
      expect(event['app']['type']).to eq('mailman')
      expect(event['device']['runtimeVersions']['mailman']).to eq(Mailman::VERSION)
      expect(event['metaData']['mailman']).to eq({ 'message' => mail })

      expect(event['severityReason']).to eq({
        'type' => Bugsnag::Report::UNHANDLED_EXCEPTION_MIDDLEWARE,
        'attributes' => { 'framework' => 'Mailman' }
      })
    }
  end

  after do
    Object.send(:remove_const, :Mailman) if @mocked_mailman
    module Kernel
      alias_method :require, :old_require
    end
  end
end


describe Bugsnag::Middleware::Mailman do
  it "adds mailman message to the metadata" do
    callback = double

    report = double("Bugsnag::Report")
    expect(report).to receive(:request_data).and_return({
      :mailman_msg => "test message"
    })

    expect(report).to receive(:add_tab).with(:mailman, {
      "message" => "test message"
    })

    expect(callback).to receive(:call).with(report)

    middleware = Bugsnag::Middleware::Mailman.new(callback)
    middleware.call(report)
  end
end
