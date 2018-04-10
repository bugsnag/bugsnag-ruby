require './app'

configure_basics

Bugsnag.configure do |conf|
  conf.meta_data_filters << :filter_me
end

Bugsnag.notify(RuntimeError.new("Oh no")) do |report|
  report.add_tab(:filter, {
    :filter_me => "NO FILTER"
  })
end