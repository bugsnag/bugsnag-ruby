require './app'

configure_basics

begin
  raise RuntimeError.new("NotifyException")
rescue => exception
  Bugsnag.notify(exception) do |report|
    report.add_tab(:account, {
      :id => "1234abcd",
      :name => "Acme Co",
      :support => true
    })
  end
end
