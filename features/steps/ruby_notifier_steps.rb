require "json"
require "net/http"

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

# Due to an ongoing discussion on whether the `payload_version` needs to be present within the headers
# and body of the payload, this step is a local replacement for the similar step present in the main
# maze-runner library. Once the discussion is resolved this step should be removed and replaced in scenarios
# with the main library version.
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

Given("I start the rails service") do
  steps %Q{
    When I start the service "#{RAILS_FIXTURE.docker_service}"
    And I wait for the host "#{RAILS_FIXTURE.host}" to open port "#{RAILS_FIXTURE.port}"
  }
end

When("I navigate to the route {string} on the rails app") do |route|
  RAILS_FIXTURE.navigate_to(route)
end

When("I run {string} in the rails app") do |command|
  steps %Q{
    When I run the service "rails#{ENV['RAILS_VERSION']}" with the command "#{command}"
  }
end

When("I run the {string} rake task in the rails app") do |task|
  steps %Q{
    When I run "bundle exec rake #{task}" in the rails app
  }
end

When("I run {string} with the rails runner") do |code|
  steps %Q{
    When I run "bundle exec rails runner '#{code}'" in the rails app
  }
end

Given("I start the rack service") do
  steps %Q{
    When I start the service "#{RACK_FIXTURE.docker_service}"
    And I wait for the host "#{RACK_FIXTURE.host}" to open port "#{RACK_FIXTURE.port}"
  }
end

When("I navigate to the route {string} on the rack app") do |route|
  RACK_FIXTURE.navigate_to(route)
end

When("I navigate to the route {string} on the rack app with these cookies:") do |route, data|
  # e.g. { "a" => "b", "c" => "d" } -> "a=b;c=d"
  cookie = data.rows_hash.map { |key, value| "#{key}=#{value}" }.join(";")

  RACK_FIXTURE.navigate_to(route, { "Cookie" => cookie })
end

When("I send a POST request to {string} in the rack app with the following form data:") do |route, data|
  RACK_FIXTURE.post_form(route, data.rows_hash)
end

When("I send a POST request to {string} in the rack app with the following JSON:") do |route, data|
  RACK_FIXTURE.post_json(route, data.rows_hash)
end

Then("the payload field {string} matches the appropriate Sidekiq handled payload") do |field|
  # Sidekiq 2 doesn't include the "created_at" field
  created_at_present = ENV["SIDEKIQ_VERSION"] > "2"

  steps %Q{
    And the payload field "#{field}" matches the JSON fixture in "features/fixtures/sidekiq/payloads/handled_metadata_ca_#{created_at_present}.json"
  }
end

Then("the payload field {string} matches the appropriate Sidekiq unhandled payload") do |field|
  # Sidekiq 2 doesn't include the "created_at" field
  created_at_present = ENV["SIDEKIQ_VERSION"] > "2"

  steps %Q{
    And the payload field "#{field}" matches the JSON fixture in "features/fixtures/sidekiq/payloads/unhandled_metadata_ca_#{created_at_present}.json"
  }
end

Then("in Rails versions {string} {int} the event {string} equals {string}") do |operator, version, path, expected|
  if RAILS_FIXTURE.version_matches?(operator, version)
    steps %Q{
      And the event "#{path}" equals "#{expected}"
    }
  else
    steps %Q{
      And the event "#{path}" is null
    }
  end
end

Then("in Rails versions {string} {int} the event {string} equals {int}") do |operator, version, path, expected|
  if RAILS_FIXTURE.version_matches?(operator, version)
    steps %Q{
      And the event "#{path}" equals #{expected}
    }
  else
    steps %Q{
      And the event "#{path}" is null
    }
  end
end

Then("in Rails versions {string} {int} the event {string} matches {string}") do |operator, version, path, expected|
  if RAILS_FIXTURE.version_matches?(operator, version)
    steps %Q{
      And the event "#{path}" matches "#{expected}"
    }
  else
    steps %Q{
      And the event "#{path}" is null
    }
  end
end

Then("in Rails versions {string} {int} the event {string} is a timestamp") do |operator, version, path|
  if RAILS_FIXTURE.version_matches?(operator, version)
    steps %Q{
      And the event "#{path}" is a timestamp
    }
  else
    steps %Q{
      And the event "#{path}" is null
    }
  end
end

Then("the event {string} matches the current Que version") do |path|
  # append a '.' to make this assertion stricter, e.g. if QUE_VERSION is '1'
  # we'll use '1.'
  que_version = ENV.fetch("QUE_VERSION") + "."

  steps %Q{
    And the event "#{path}" starts with "#{que_version}"
  }
end
