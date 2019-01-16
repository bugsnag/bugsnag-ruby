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

Then(/^the "(.+)" of the top non-bugsnag stackframe equals (\d+|".+")(?: for request (\d+))?$/) do |element, value, request_index|
  stacktrace = read_key_path(find_request(request_index)[:body], 'events.0.exceptions.0.stacktrace')
  frame_index = stacktrace.find_index { |frame| ! /.*lib\/bugsnag.*\.rb/.match(frame["file"]) }
  steps %Q{
    the "#{element}" of stack frame #{frame_index} equals #{value}
  }
end

Then(/^the total sessionStarted count equals (\d+)(?: for request (\d+))?$/) do |value, request_index|
  session_counts = read_key_path(find_request(request_index)[:body], "sessionCounts")
  total_count = session_counts.inject(0) { |count, session| count += session["sessionsStarted"] }
  assert_equal(value, total_count)
end