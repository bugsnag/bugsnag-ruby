Then(/^the "(.+)" of the top non-bugsnag stackframe equals (\d+|".+")$/) do |element, value|
  stacktrace = read_key_path(Server.current_request[:body], 'events.0.exceptions.0.stacktrace')
  frame_index = stacktrace.find_index { |frame| ! /.*lib\/bugsnag.*\.rb/.match(frame["file"]) }
  steps %Q{
    the "#{element}" of stack frame #{frame_index} equals #{value}
  }
end

Then(/^the total sessionStarted count equals (\d+)$/) do |value|
  session_counts = read_key_path(Server.current_request[:body], "sessionCounts")
  total_count = session_counts.inject(0) { |count, session| count += session["sessionsStarted"] }
  assert_equal(value, total_count)
end


### THIS NEEDS TO BE REMOVED BEFORE MERGING
Then("the request is valid for the error reporting API version {string} for the {string}") do |payload_version, notifier_name|
  steps %Q{
    Then the "Bugsnag-Api-Key" header equals "#{$api_key}"
    And the payload field "apiKey" equals "#{$api_key}"
    And the "Bugsnag-Payload-Version" header equals "#{payload_version}"
    And the "Content-Type" header equals "application/json"
    And the "Bugsnag-Sent-At" header is a timestamp

    And the payload field "notifier.name" equals "#{notifier_name}"
    And the payload field "notifier.url" is not null
    And the payload field "notifier.version" is not null
    And the payload field "events" is a non-empty array

    And each element in payload field "events" has "severity"
    And each element in payload field "events" has "severityReason.type"
    And each element in payload field "events" has "unhandled"
    And each element in payload field "events" has "exceptions"
  }
end

Given("I set environment variable {string} to the testing host") do |variable|
  steps %Q{
    When I set environment variable "#{variable}" to "http://maze-runner"
  }
end

Given("I set environment variable {string} to the testing port") do |variable|
  steps %Q{
    When I set environment variable "#{variable}" to "#{MOCK_API_PORT}"
  }
end

Given("I set environment variable {string} to target the test server with credentials {string}") do |variable, credentials|
  steps %Q{
    When I set environment variable "#{variable}" to "#{credentials}@maze-runner:#{MOCK_API_PORT}"
  }
end

Given("I start the rails service") do
  rails_version = ENV["RAILS_VERSION"]
  steps %Q{
    When I start the service "rails#{rails_version}"
    And I wait for the host "rails#{rails_version}" to open port "6128#{rails_version}"
  }
end

When("I navigate to the route {string} on the rails app") do |route|
  rails_version = ENV["RAILS_VERSION"]
  steps %Q{
    When I open the URL "rails#{rails_version}:6128#{rails_version}#{route}"
  }
end