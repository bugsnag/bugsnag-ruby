require './app'

configure_basics

Bugsnag.configure do |conf|
  conf.delivery_method = :synchronous
end

Bugsnag.notify("handled string") do |report|
  report.add_tab(:config, {
    :delivery_method => "synchronous",
    :forked => false
  })
end