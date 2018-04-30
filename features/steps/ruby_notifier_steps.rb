require 'net/http'
require 'open3'
require 'pp'

When("I configure the bugsnag endpoint") do
  steps %Q{
    When I set environment variable "MAZE_ENDPOINT" to "http://#{current_ip}:#{MOCK_API_PORT}"
  }
end

When("I wait for the app to respond on port {string}") do |port|
  max_attempts = ENV.include?('MAX_MAZE_CONNECT_ATTEMPTS')? ENV['MAX_MAZE_CONNECT_ATTEMPTS'].to_i : 10
  pp "Max attempts: #{max_attempts}"
  attempts = 0
  up = false
  until (attempts >= max_attempts) || up
    pp "Attempt: #{attempts}, Time: #{Time.now}"
    attempts += 1
    begin
      uri = URI("http://localhost:#{port}/")
      response = Net::HTTP.get_response(uri)
      pp response
      up = (response.code == "200")
    rescue EOFError
    end
    sleep 1
  end
  raise "App not ready in time!" unless up
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

Then("the request used payload v4 headers") do
  steps %Q{
    Then the "bugsnag-api-key" header is not null
    And the "bugsnag-payload-version" header equals "4.0"
    And the "bugsnag-sent-at" header is a timestamp
  }
end

Then("the request contained the api key {string}") do |api_key|
  steps %Q{
    Then the "bugsnag-api-key" header equals "#{api_key}"
    And the payload field "apiKey" equals "#{api_key}"
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