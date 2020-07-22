Bugsnag.configure do |config|
  config.api_key = "YOUR_API_KEY_HERE"

  config.add_on_error(proc do |report|
    report.add_tab(:user, {
      username: 'bob-hoskins',
      email: 'bugsnag@bugsnag.com',
      registered_user: true
    })
  end)
end
