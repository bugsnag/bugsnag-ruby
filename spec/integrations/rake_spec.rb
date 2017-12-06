require 'spec_helper'

describe Bugsnag::Middleware::Rake do
  it "adds rake data to the report" do
    callback = double

    task = double
    allow(task).to receive_messages(
      :name => "TEST_NAME",
      :full_comment => "TEST_COMMENT",
      :arg_description =>"TEST_ARGS"
    )

    report = double("Bugsnag::Report") 
    expect(report).to receive(:request_data).and_return({
      :bugsnag_running_task => task
    })
    expect(report).to receive(:add_tab).with(:rake_task, {
      :name => "TEST_NAME",
      :description => "TEST_COMMENT",
      :arguments => "TEST_ARGS"
    })
    expect(report).to receive(:context).with(no_args)
    expect(report).to receive(:context=).with("TEST_NAME")

    expect(callback).to receive(:call).with(report)

    middleware = Bugsnag::Middleware::Rake.new(callback)
    middleware.call(report)
  end
end