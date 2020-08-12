# encoding: utf-8
require 'spec_helper'

describe 'Bugsnag::Shoryuken', :order => :defined do
  before do
    unless defined?(::Shoryuken)
      @mocked_shoryuken = true
      class Shoryuken
        VERSION = '1.2.3'
      end
      module Kernel
        alias_method :old_require, :require
        def require(path)
          old_require(path) unless path == 'shoryuken'
        end
      end
    end
  end

  it "should call configure_server" do
    chain = double("chain")
    expect(chain).to receive(:add).with(anything())
    config = double("config")
    expect(config).to receive(:server_middleware).and_yield(chain)
    expect(::Shoryuken).to receive(:configure_server).and_yield(config)

    require './lib/bugsnag/integrations/shoryuken'
  end

  it "calls configure when initialised" do
    Bugsnag::Shoryuken.new

    expect(Bugsnag.configuration.app_type).to eq("shoryuken")
    expect(Bugsnag.configuration.delivery_method).to eq(:synchronous)
    expect(Bugsnag.configuration.runtime_versions["shoryuken"]).to eq(Shoryuken::VERSION)
  end

  it "calls correct sequence when called" do
    queue = 'a queue name'
    body = 'the body of a queued message'
    exception = RuntimeError.new('oops')

    expect {
      Bugsnag::Shoryuken.new.call('_', queue, '_', body) { raise exception }
    }.to raise_error(exception)

    expect(Bugsnag).to have_sent_notification { |payload, headers|
      event = get_event_from_payload(payload)

      expect(event['unhandled']).to be(true)
      expect(event['severity']).to eq('error')
      expect(event['app']['type']).to eq('shoryuken')
      expect(event['device']['runtimeVersions']['shoryuken']).to eq(Shoryuken::VERSION)

      expect(event['metaData']['shoryuken']).to eq({
        'body' => body,
        'queue' => queue,
      })

      expect(event['severityReason']).to eq({
        'type' => Bugsnag::Report::UNHANDLED_EXCEPTION_MIDDLEWARE,
        'attributes' => { 'framework' => 'Shoryuken' }
      })
    }
  end

  after do
    Object.send(:remove_const, :Shoryuken) if @mocked_shoryuken
    module Kernel
      alias_method :require, :old_require
    end
  end
end
