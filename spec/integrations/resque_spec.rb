# encoding: utf-8
require 'spec_helper'

describe 'Bugsnag::Resque', :order => :defined do
  before do
    unless defined?(::Resque)
      @mocked_resque = true
      class ::Resque
        VERSION = '9.9.9'
        class Worker
        end
        class Failure
          class Bugsnag
          end
          class Base
          end
          class Multiple
          end
        end
      end
      module Kernel
        alias_method :old_require, :require
        def require(path)
          old_require(path) unless /^resque/.match(path)
        end
      end
    end
  end

  it "should load Bugsnag::Resque" do
    #Auto-load failure backend
    backend = double('backend')
    allow(::Resque::Failure).to receive(:backend).and_return(backend)
    expect(backend).to receive(:<).and_return(nil)
    expect(::Resque::Failure).to receive(:backend=).with(::Resque::Failure::Multiple)
    classes = double('classes')
    allow(backend).to receive(:classes).and_return(classes)
    expect(classes).to receive(:<<).with(backend)
    expect(classes).to receive(:include?).and_return(false)
    expect(classes).to receive(:<<)

    #Bugsnag fork check
    fork_check = double("fork_check")
    expect(::Resque::Worker).to receive(:new).with(:bugsnag_fork_check).and_return(fork_check)
    expect(fork_check).to receive(:fork_per_job?).and_return(true)
    expect(::Resque).to receive(:after_fork).and_yield
    expect(Bugsnag.configuration).to receive(:app_type=).with("resque")
    runtime = {}
    expect(Bugsnag.configuration).to receive(:runtime_versions).and_return(runtime)
    expect(Bugsnag.configuration).to receive(:default_delivery_method=).with(:synchronous)

    #Kick off
    require './lib/bugsnag/integrations/resque'

    expect(runtime).to eq("resque" => "9.9.9")
  end

  it "can configure" do
    expect(Bugsnag::Resque).to receive(:add_failure_backend)
    expect(Bugsnag).to receive(:configure).and_yield
    Bugsnag::Resque.configure do
    end
  end

  it "can save data" do
    resque = Bugsnag::Resque.new
    exception = double('exception')
    allow(resque).to receive(:exception).and_return(exception)
    allow(resque).to receive(:payload).and_return({
      "class" => "class"
    })
    allow(resque).to receive(:queue).and_return("queue")
    report = double('report')
    expect(report).to receive(:severity=).with("error")
    expect(report).to receive(:severity_reason=).with({
      :type => Bugsnag::Report::UNHANDLED_EXCEPTION_MIDDLEWARE,
      :attributes => Bugsnag::Resque::FRAMEWORK_ATTRIBUTES
    })
    expected_context = "class@queue"
    meta_data = double('meta_data')
    expect(report).to receive(:meta_data).and_return(meta_data)
    expect(meta_data).to receive(:merge!).with({
      :context => expected_context,
      :payload => {
        "class" => "class"
      }
    })
    expect(report).to receive(:context=).with(expected_context)
    expect(Bugsnag).to receive(:notify).with(exception, true).and_yield(report)
    resque.save
  end

  after do
    Object.send(:remove_const, :Resque) if @mocked_resque
    module Kernel
      alias_method :require, :old_require
    end
  end
end
