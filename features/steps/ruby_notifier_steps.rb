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