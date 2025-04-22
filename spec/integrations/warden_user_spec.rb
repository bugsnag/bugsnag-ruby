require "spec_helper"

describe Bugsnag::Middleware::WardenUser do
  it "updates the reports user with warden parameters" do
    callback = double

    user = double
    allow(user).to receive_messages(
      email: "TEST_EMAIL",
      name: "TEST_NAME",
      created_at: "TEST_NOW",
    )

    warden = double
    allow(warden).to receive(:user).with({
      scope: "user",
      run_callbacks: false,
    }).and_return(user)

    report = double("Bugsnag::Report") 
    expect(report).to receive(:request_data).exactly(3).times.and_return({
      rack_env: {
        "warden" => warden,
        "rack.session" => {
          "warden.user.user.key" => "TEST_USER",
        }
      }
    })

    expect(report).to receive(:user=).with({
      email: "TEST_EMAIL",
      name: "TEST_NAME",
      created_at: "TEST_NOW",
      warden_scope: "user",
    })

    expect(callback).to receive(:call).with(report)

    middleware = Bugsnag::Middleware::WardenUser.new(callback)
    middleware.call(report)
  end

  it "sets the scope to the 'best scope'" do
    callback = double

    user = double
    allow(user).to receive_messages(
      email: "TEST_EMAIL",
      name: "TEST_NAME",
      created_at: "TEST_NOW",
    )

    warden = double
    allow(warden).to receive(:user).with({
      scope: "admin",
      run_callbacks: false,
    }).and_return(user)

    report = double("Bugsnag::Report")
    expect(report).to receive(:request_data).exactly(3).times.and_return({
      :rack_env => {
        "warden" => warden,
        "rack.session" => {
          "warden.user.admin.key" => "TEST_USER"
        }
      }
    })

    expect(report).to receive(:user=).with({
      email: "TEST_EMAIL",
      name: "TEST_NAME",
      created_at: "TEST_NOW",
      warden_scope: "admin",
    })

    expect(callback).to receive(:call).with(report)

    middleware = Bugsnag::Middleware::WardenUser.new(callback)
    middleware.call(report)
  end

  it "doesn't set the user if the user object is empty" do
    callback = double

    warden = double
    allow(warden).to receive(:user).with({
      scope: "user",
      run_callbacks: false,
    }).and_return(nil)

    report = double("Bugsnag::Report")
    expect(report).to receive(:request_data).exactly(3).times.and_return({
      :rack_env => {
        "warden" => warden,
        "rack.session" => {
          "warden.user.user.key" => "TEST_USER"
        }
      }
    })

    expect(report).not_to receive(:user=)

    expect(callback).to receive(:call).with(report)

    middleware = Bugsnag::Middleware::WardenUser.new(callback)
    middleware.call(report)
  end
end
