require 'os'
require 'fileutils'
require_relative "./../lib/fixture"

RACK_FIXTURE = Fixture.new("rack", ENV["RACK_VERSION"])
RAILS_FIXTURE = Fixture.new("rails", ENV["RAILS_VERSION"])

def running_in_docker?
  File.exist?("/app/bugsnag.gem")
end

def install_fixture_gems
  if running_in_docker?
    # running in docker so the gem is built already
    bugsnag_gem_path = "/app/bugsnag.gem"
  else
    # running locally so we need to build the gem
    `gem build bugsnag.gemspec -o bugsnag.gem`
    bugsnag_gem_path = "#{__dir__}/../../bugsnag.gem"
  end

  Dir.entries('features/fixtures').reject { |entry| ['.', '..'].include?(entry) }.each do |entry|
    target_dir = "features/fixtures/#{entry}"
    if File.directory?(target_dir)
      `cp #{bugsnag_gem_path} #{target_dir}`
      `gem unpack #{target_dir}/bugsnag.gem --target #{target_dir}/temp-bugsnag-lib`
    end
  end
ensure
  File.unlink(bugsnag_gem_path)
end

def current_ip
  return "host.docker.internal" if OS.mac?

  ip_addr = `ifconfig | grep -Eo 'inet (addr:)?([0-9]*\\\.){3}[0-9]*' | grep -v '127.0.0.1'`
  ip_list = /((?:[0-9]*\.){3}[0-9]*)/.match(ip_addr)
  ip_list.captures.first
end


AfterConfiguration do |config|
  install_fixture_gems
end

Before do
  Docker.compose_project_name = "#{rand.to_s}:#{Time.new.strftime("%s")}"
  Runner.environment.clear
  Runner.environment["BUGSNAG_API_KEY"] = $api_key

  if running_in_docker?
    Runner.environment["BUGSNAG_ENDPOINT"] = "http://maze-runner:#{MOCK_API_PORT}"
  else
    Runner.environment["BUGSNAG_ENDPOINT"] = "http://#{current_ip}:#{MOCK_API_PORT}"
  end
end
