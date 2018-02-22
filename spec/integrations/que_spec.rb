# encoding: utf-8
require 'spec_helper'

describe 'Bugsnag::Que', :order => :defined do
  before do
    unless defined?(::Que)
      @mocked_que = true
      class ::Que
        Version = 'test'
      end
    end
  end

  it "should create and register a que handler" do
    error = RuntimeError.new("oops")
    job = double('que_job')
    expect(job).to receive(:dup).and_return({
      :error_count => 0,
      :job_class => 'ActiveJob::QueueAdapters::QueAdapter::JobWrapper',
      :args => [{"queue_name" => "foo", "arguments" => "bar"}],
      :job_id => "ID"
    })

    report = double('report')
    expect(Bugsnag).to receive(:notify).with(error, true).and_yield(report)
    expect(report).to receive(:add_tab).with(:job, {
      :error_count => 1,
      :job_class => 'ActiveJob::QueueAdapters::QueAdapter::JobWrapper',
      :args => [{"queue_name" => "foo", "arguments" => "bar"}],
      :job_id => "ID",
      :wrapper_job_class => 'ActiveJob::QueueAdapters::QueAdapter::JobWrapper',
      :wrapper_job_id => "ID",
      :queue => "foo",
      :args => "bar"
    })
    expect(report).to receive(:severity=).with("error")
    expect(report).to receive(:severity_reason=).with({
      :type => Bugsnag::Report::UNHANDLED_EXCEPTION_MIDDLEWARE,
      :attributes => {
        :framework => 'Que'
      }
    })

    framework_versions = {}
    expect(report).to receive(:app_framework_versions).and_return(framework_versions)

    allow(Que).to receive(:respond_to?).with(:error_notifier=).and_return(true)
    config = double('config')
    allow(Bugsnag).to receive(:configuration).and_return(config)
    expect(config).to receive(:app_type)
    expect(config).to receive(:app_type=).with('que')
    allow(config).to receive(:clear_request_data)
    expect(Que).to receive(:error_notifier=) do |handler|
      handler.call(error, job)
    end

    #Kick off
    load './lib/bugsnag/integrations/que.rb'

    expect(framework_versions).to include(:queVersion => 'test')
  end

  after do
    Object.send(:remove_const, :Que) if @mocked_que
  end
end
