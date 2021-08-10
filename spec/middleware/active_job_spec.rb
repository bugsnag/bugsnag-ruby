require 'spec_helper'
require 'bugsnag/middleware/active_job'

describe Bugsnag::Middleware::ActiveJob do
  it 'does nothing if there is no active_job request data' do
    report = Bugsnag::Report.new(RuntimeError.new, Bugsnag.configuration)
    middleware = Bugsnag::Middleware::ActiveJob.new(->(_) {})

    middleware.call(report)

    expect(report.context).to be_nil
    expect(report.meta_data).to eq({})
  end

  it 'attaches active_job request data as metadata and sets the context' do
    report = Bugsnag::Report.new(RuntimeError.new, Bugsnag.configuration)
    report.request_data[:active_job] = {
      abc: 123,
      xyz: 456,
      job_name: 'ExampleJob',
      queue: 'default_queue'
    }

    middleware = Bugsnag::Middleware::ActiveJob.new(->(_) {})

    middleware.call(report)

    expect(report.context).to eq('ExampleJob@default_queue')
    expect(report.meta_data).to eq({
      active_job: {
        abc: 123,
        xyz: 456,
        job_name: 'ExampleJob',
        queue: 'default_queue'
      }
    })
  end
end
