require 'net/http'
require 'open3'
require 'pp'

When("I configure the bugsnag endpoint") do
  steps %Q{
    When I set environment variable "MAZE_ENDPOINT" to "http://#{current_ip}:9291"
  }
end

When("I start the compose stack {string}") do |filename|
  $compose_stacks << filename
  environment = @script_env.inject('') {|curr,(k,v)| curr + "#{k}=#{v} "}
  run_command "#{environment} docker-compose -f #{filename} up -d --build", true
end

When("I build the service {string} from the compose file {string}") do |service, filename|
  environment = @script_env.inject('') {|curr,(k,v)| curr + "#{k}=#{v} "}
  run_command "#{environment} docker-compose -f #{filename} build --no-cache #{service}"
end

When("I run the command {string} on the service {string}") do |command, filename|
  environment = @script_env.inject('') {|curr,(k,v)| curr + "#{k}=#{v} "}
  run_command "#{environment} docker-compose -f #{filename} run #{command}"
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

Then("the event {string} is {string}") do |key, value|
  steps %Q{
    Then the payload field "events.0.#{key}" equals "#{value}"
  }
end

Then("I log the request") do
  pp stored_requests.first
end