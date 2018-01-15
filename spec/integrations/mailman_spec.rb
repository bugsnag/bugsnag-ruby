require "spec_helper"

describe 'Bugsnag::Mailman', :order => :defined do
  before do
    unless defined?(::Mailman)
      @mocked_mailman = true
      class Mailman
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
    middleware = double('mailman-config-middleware')
    expect(config).to receive(:middleware).and_return(middleware)
    expect(middleware).to receive(:add).with(any_args)

    #Kick off
    require './lib/bugsnag/integrations/mailman'
  end

  it "can be called" do
    config = double('config')
    allow(Bugsnag).to receive(:configuration).and_return(config)
    int_middleware = double('internal_middleware')
    expect(config).to receive(:internal_middleware).and_return(int_middleware)
    expect(int_middleware).to receive(:use).with(Bugsnag::Middleware::Mailman)
    expect(config).to receive(:app_type=).with("mailman")

    integration = Bugsnag::Mailman.new

    mail = double('mail')
    expect(config).to receive(:set_request_data).with(:mailman_msg, mail)
    expect(mail).to receive(:to_s).and_return(mail)
    allow(config).to receive(:clear_request_data)

    exception = RuntimeError.new('oops')
    report = double('report')
    expect(Bugsnag).to receive(:notify).with(exception, true).and_yield(report)
    expect(report).to receive(:severity=).with('error')
    expect(report).to receive(:severity_reason=).with({
      :type => Bugsnag::Report::UNHANDLED_EXCEPTION_MIDDLEWARE,
      :attributes => Bugsnag::Mailman::FRAMEWORK_ATTRIBUTES
    })
    expect{integration.call(mail) {raise exception}}.to raise_error(exception)
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
