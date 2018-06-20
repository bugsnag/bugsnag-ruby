require './app'

configure_basics

Bugsnag.notify(RuntimeError.new("Oh no")) do |report|
  report.add_tab(:filter, {
    :authorization => "authorization",
    :cookie => "cookie",
    :password => "password",
    :secret => "secret",
    :"warden.user.user.key" => "warden user key",
    :"rack.request.form_vars" => "rack request form vars",
    :filter_me => "NO FILTER"
  })
end