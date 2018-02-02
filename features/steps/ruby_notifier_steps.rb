require 'net/http'
require 'open3'

When("I configure the bugsnag endpoint") do
  steps %Q{
    When I set environment variable "endpoint" to "http://#{current_ip}:9291"
  }
end

When("I start the compose stack {string}") do |filename|
  $compose_stacks << filename
  environment = @script_env.inject('') {|curr,(k,v)| curr + "#{k}=#{v} "}
  run_command "#{environment} docker-compose -f #{filename} up -d --build"
end

When("I wait for the app to respond on port {string}") do |port|
  attempts = 0
  up = false
  until attempts >= 10 || up
    attempts += 1
    begin
      uri = URI("http://localhost:#{port}/")
      response = Net::HTTP.get_response(uri)
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

Then("the request used the Ruby notifier") do
  steps %Q{
    Then the payload field "notifier.name" equals "Ruby Bugsnag Notifier"
    And the payload field "notifier.url" equals "http://www.bugsnag.com"
  }
end
