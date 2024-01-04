require "json"
require "net/http"

Then(/^the "(.+)" of the top non-bugsnag stackframe equals (\d+|".+")$/) do |element, value|
  body = Maze::Server.errors.current[:body]
  stacktrace = Maze::Helper.read_key_path(body, 'events.0.exceptions.0.stacktrace')

  frame_index = stacktrace.find_index { |frame| ! /.*lib\/bugsnag.*\.rb/.match(frame["file"]) }

  steps %Q{
    the "#{element}" of stack frame #{frame_index} equals #{value}
  }
end

Then(/^the "(.+)" of the first in-project stack frame equals (\d+|".+")$/) do |key, expected|
  body = Maze::Server.errors.current[:body]
  stacktrace = Maze::Helper.read_key_path(body, 'events.0.exceptions.0.stacktrace')

  frame_index = stacktrace.find_index { |frame| frame["inProject"] == true }

  if frame_index.nil?
    raise "Unable to find an in-project stack frame in stacktrace: #{stacktrace.inspect}"
  end

  steps %Q{
    the "#{key}" of stack frame #{frame_index} equals #{expected}
  }
end

Then(/^the total sessionStarted count equals (\d+)$/) do |value|
  body = Maze::Server.sessions.current[:body]
  session_counts = Maze::Helper.read_key_path(body, "sessionCounts")

  total_count = session_counts.sum { |session| session["sessionsStarted"] }
  assert_equal(value, total_count)
end

Given("I start the rails service") do
  steps %Q{
    When I start the service "#{RAILS_FIXTURE.docker_service}"
    And I wait for the host "#{RAILS_FIXTURE.host}" to open port "#{RAILS_FIXTURE.port}"
  }
end

Given("I start the rails service with the database") do
  steps %Q{
    Given I start the rails service
    And I run the "db:prepare" rake task in the rails app
    And I run the "db:migrate" rake task in the rails app
  }
end

When("I navigate to the route {string} on the rails app") do |route|
  RAILS_FIXTURE.navigate_to(route)
end

When("I run {string} in the rails app") do |command|
  steps %Q{
    When I execute the command "#{command}" in the service "rails#{ENV['RAILS_VERSION']}"
  }
end

When("I run {string} in the rails app in the background") do |command|
  steps %Q{
    When I execute the command "#{command}" in the service "rails#{ENV['RAILS_VERSION']}" in the background
  }
end

When("I run the {string} rake task in the rails app") do |task|
  steps %Q{
    When I run "bundle exec rake #{task}" in the rails app
  }
end

When("I run the {string} rake task in the rails app in the background") do |task|
  steps %Q{
    When I run "bundle exec rake #{task}" in the rails app in the background
  }
end

When("I run {string} with the rails runner") do |code|
  steps %Q{
    When I execute the command "bundle exec rails runner #{code}" in the service "rails#{ENV['RAILS_VERSION']}"
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

Then("the event {string} matches the appropriate Sidekiq handled payload") do |field|
  # Sidekiq 2 doesn't include the "created_at" field
  created_at_present = ENV["SIDEKIQ_VERSION"] > "2"

  steps %Q{
    And the event "#{field}" matches the JSON fixture in "features/fixtures/sidekiq/payloads/handled_metadata_ca_#{created_at_present}.json"
  }
end

Then("the event {string} matches the appropriate Sidekiq unhandled payload") do |field|
  # Sidekiq 2 doesn't include the "created_at" field
  created_at_present = ENV["SIDEKIQ_VERSION"] > "2"

  steps %Q{
    And the event "#{field}" matches the JSON fixture in "features/fixtures/sidekiq/payloads/unhandled_metadata_ca_#{created_at_present}.json"
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

Given("I configure the BUGSNAG_PROXY environment variables") do
  host = running_in_docker? ? "maze-runner" : current_ip

  steps %Q{
    When I set environment variable "BUGSNAG_PROXY_HOST" to "#{host}"
    And I set environment variable "BUGSNAG_PROXY_PORT" to "#{Maze.config.port}"
    And I set environment variable "BUGSNAG_PROXY_USER" to "tester"
    And I set environment variable "BUGSNAG_PROXY_PASSWORD" to "testpass"
  }
end

Given("I configure the http_proxy environment variable") do
  host = running_in_docker? ? "maze-runner" : current_ip

  steps %Q{
    Given I set environment variable "http_proxy" to "http://tester:testpass@#{host}:#{Maze.config.port}"
  }
end

Given("I configure the https_proxy environment variable") do
  host = running_in_docker? ? "maze-runner" : current_ip

  steps %Q{
    Given I set environment variable "https_proxy" to "https://tester:testpass@#{host}:#{Maze.config.port}"
  }
end
