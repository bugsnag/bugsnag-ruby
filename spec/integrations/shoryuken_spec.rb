# encoding: utf-8
require 'spec_helper'

describe 'Bugsnag::Shoryuken', :order => :defined do
  before do
    unless defined?(::Shoryuken)
      @mocked_shoryuken = true
      class ::Shoryuken
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
    config = double("config")

    expect(config).to receive(:detected_app_type=).with("shoryuken")
    expect(config).to receive(:default_delivery_method=).with(:synchronous)
    expect(Bugsnag).to receive(:configure).and_yield(config)
    Bugsnag::Shoryuken.new
  end

  it "calls correct sequence when called" do
    queue = 'queue'
    body = 'body'

    callbacks = double('callbacks')
    expect(callbacks).to receive(:<<) do |func|
      report = double('report')
      expect(report).to receive(:add_tab).with(:shoryuken, {
        queue: queue,
        body: body
      })
      func.call(report)
    end
    config = double('config')
    allow(config).to receive(:detected_app_type=).with("shoryuken")
    allow(config).to receive(:default_delivery_method=).with(:synchronous)
    allow(config).to receive(:clear_request_data)
    expect(Bugsnag).to receive(:before_notify_callbacks).and_return(callbacks)
    allow(Bugsnag).to receive(:configure).and_yield(config)
    allow(Bugsnag).to receive(:configuration).and_return(config)
    shoryuken = Bugsnag::Shoryuken.new
    expect { |b| shoryuken.call('_', queue, '_', body, &b )}.to yield_control
  end

  after do
    Object.send(:remove_const, :Shoryuken) if @mocked_shoryuken
    module Kernel
      alias_method :require, :old_require
    end
  end
end
