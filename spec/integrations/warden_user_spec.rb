require "spec_helper"

describe Bugsnag::Middleware::WardenUser do
  it "updates the reports user with warden parameters" do
    callback = double

    user = double
    allow(user).to receive_messages(
      :email => "TEST_EMAIL",
      :name => "TEST_NAME",
      :created_at => "TEST_NOW"
    )

    warden = double
    allow(warden).to receive(:user).with(
      :scope => "user",
      :run_callbacks => false
    ).and_return(user)

    report = double("Bugsnag::Report") 
    expect(report).to receive(:request_data).exactly(3).times.and_return({
      :rack_env => {
        "warden" => warden,
        "rack.session" => {
          "warden.user.user.key" => "TEST_USER"
        }
      }
    })

    expect(report).to receive(:user=).with({
      :email => "TEST_EMAIL",
      :name => "TEST_NAME",
      :created_at => "TEST_NOW"
    })

    expect(callback).to receive(:call).with(report)

    middleware = Bugsnag::Middleware::WardenUser.new(callback)
    middleware.call(report)
  end
end
