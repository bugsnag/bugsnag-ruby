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
  File.unlink(bugsnag_gem_path) unless running_in_docker?
end

def current_ip
  return "host.docker.internal" if OS.mac?

  ip_addr = `ifconfig | grep -Eo 'inet (addr:)?([0-9]*\\\.){3}[0-9]*' | grep -v '127.0.0.1'`
  ip_list = /((?:[0-9]*\.){3}[0-9]*)/.match(ip_addr)
  ip_list.captures.first
end

Maze.hooks.before_all do
  install_fixture_gems

  # log to console, not a file
  Maze.config.file_log = false
  Maze.config.log_requests = true

  # don't wait so long for requests/not to receive requests locally
  unless ENV["CI"]
    Maze.config.receive_requests_wait = 10
    Maze.config.receive_no_requests_wait = 10
  end

  # bugsnag-ruby doesn't need to send the integrity header
  Maze.config.enforce_bugsnag_integrity = false
end

Maze.hooks.before do
  Maze::Runner.environment["BUGSNAG_API_KEY"] = $api_key

  host = running_in_docker? ? "maze-runner" : current_ip

  Maze::Runner.environment["BUGSNAG_ENDPOINT"] = "http://#{host}:#{Maze.config.port}/notify"
  Maze::Runner.environment["BUGSNAG_SESSION_ENDPOINT"] = "http://#{host}:#{Maze.config.port}/sessions"
end
