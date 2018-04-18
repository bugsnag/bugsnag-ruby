require './app'

configure_basics

Bugsnag.configure do |conf|
  conf.delivery_method = :thread_queue
end

Bugsnag.notify("handled string") do |report|
  report.add_tab(:config, {
    :delivery_method => "thread_queue",
    :forked => true
  })
end

Process.fork do
  Bugsnag.notify("handled string number 2") do |report|
    report.add_tab(:config, {
      :delivery_method => "thread_queue",
      :forked => true
    })
  end
end

Process.wait