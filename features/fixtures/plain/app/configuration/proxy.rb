require './app'

configure_basics

configure_using_environment

Bugsnag.notify(RuntimeError.new("Oh no")) do |report|
  report.add_tab(:proxy, {
    :host => Bugsnag.configuration.proxy_host,
    :port => Bugsnag.configuration.proxy_port,
    :user => Bugsnag.configuration.proxy_user,
    :password => Bugsnag.configuration.proxy_password
  })
end