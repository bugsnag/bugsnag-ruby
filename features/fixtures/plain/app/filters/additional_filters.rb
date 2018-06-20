require './app'

configure_basics

configure_using_environment

Bugsnag.notify(RuntimeError.new("Oh no")) do |report|
  report.add_tab(:filter, {
    :filter_me => "NO FILTER"
  })
end