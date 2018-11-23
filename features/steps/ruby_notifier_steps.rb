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
Then(/^the "(.+)" of the top project stackframe equals "(.+)"(?: for request (\d+))?$/) do |element, value, request_index|
  stacktrace = read_key_path(find_request(request_index)[:body], 'events.0.exceptions.0.stacktrace')
  frame_index = 0
  stacktrace.each do |frame, index|
    unless /.*lib\/bugsnag.*\.rb/.match(frame["file"])
      frame_index = index
      break
    end
  end
  steps %Q{
    the "#{element}" of stack frame #{frame_index} equals "#{value}"
  }
end
Then(/^the "(.+)" of the top project stackframe equals (\d+)(?: for request (\d+))?$/) do |element, value, request_index|
  stacktrace = read_key_path(find_request(request_index)[:body], 'events.0.exceptions.0.stacktrace')
  frame_index = 0
  stacktrace.each do |frame, index|
    unless /.*lib\/bugsnag.*\.rb/.match(frame["file"])
      frame_index = index
      break
    end
  end
  steps %Q{
    the "#{element}" of stack frame #{frame_index} equals #{value}
  }
end