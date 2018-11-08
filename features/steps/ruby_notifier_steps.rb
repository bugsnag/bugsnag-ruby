require 'net/http'
require 'open3'

When("I configure the bugsnag endpoint") do
  steps %Q{
    When I set environment variable "MAZE_ENDPOINT" to "http://#{current_ip}:#{MOCK_API_PORT}"
  }
end

When("I navigate to the route {string} on port {string}") do |route, port|
  steps %Q{
    When I open the URL "http://localhost:#{port}#{route}"
    And I wait for 1 second
  }
end

When("I set environment variable {string} to the current IP") do |env_var|
  steps %Q{
    When I set environment variable "#{env_var}" to "#{current_ip}"
  }
end
When("I set environment variable {string} to the mock API port") do |env_var|
  steps %Q{
    When I set environment variable "#{env_var}" to "#{MOCK_API_PORT}"
  }
end
When("I set environment variable {string} to the proxy settings with credentials {string}") do |env_var, credentials|
  steps %Q{
    When I set environment variable "#{env_var}" to "#{credentials}@#{current_ip}:#{MOCK_API_PORT}"
  }
end
Then("the request used the Ruby notifier") do
  bugsnag_regex = /^http(s?):\/\/www.bugsnag.com/
  steps %Q{
    Then the payload field "notifier.name" equals "Ruby Bugsnag Notifier"
    And the payload field "notifier.url" matches the regex "#{bugsnag_regex}"
  }
end

Then("the event {string} is {string}") do |key, value|
  steps %Q{
    Then the event "#{key}" equals "#{value}"
  }
end