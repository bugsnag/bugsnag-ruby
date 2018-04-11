require './app'

configure_basics

Bugsnag.configure do |conf|
  conf.delivery_method = :thread_queue
end

Bugsnag.notify("handled string") do |report|
  report.add_tab(:config, {
    :delivery_method => "thread_queue",
    :forked => false
  })
end