require 'os'
require 'fileutils'

def install_fixture_gems
  throw Error.new("Bugsnag.gem not found. Is this running in a docker-container?") unless File.exist?("/app/bugsnag.gem")
  Dir.entries('features/fixtures').reject { |entry| ['.', '..'].include?(entry) }.each do |entry|
    target_dir = "features/fixtures/#{entry}"
    if File.directory?(target_dir)
      `cp /app/bugsnag.gem #{target_dir}`
      `gem unpack #{target_dir}/bugsnag.gem --target #{target_dir}/temp-bugsnag-lib`
    end
  end
end

def current_ip
  return "host.docker.internal" if OS.mac?

  pp `ifconfig`
  pp `ifconfig | grep -Eo 'inet (addr:)?([0-9]*\\\.){3}[0-9]*'`

  ip_addr = `ifconfig | grep -Eo 'inet (addr:)?([0-9]*\\\.){3}[0-9]*' | grep -v '127.0.0.1'`
  ip_list = /((?:[0-9]*\.){3}[0-9]*)/.match(ip_addr)
  ip_list.captures.first
end

if defined?(Maze::Hooks)
  Maze.hooks.before_all do
    install_fixture_gems

    # log to console, not the file
    Maze.config.file_log = false
    Maze.config.log_requests = true

    # don't wait so long for requests/not to receive requests
    Maze.config.receive_requests_wait = 10
    Maze.config.receive_no_requests_wait = 10

    # bugsnag-ruby doesn't need to send the integrity header
    Maze.config.enforce_bugsnag_integrity = false
  end

  Maze.hooks.before do


    # Maze::Docker.compose_project_name = "#{rand.to_s}:#{Time.new.strftime("%s")}"

    ENV["BUGSNAG_API_KEY"] = $api_key
    ENV["BUGSNAG_ENDPOINT"] = "http://maze-runner:#{Maze.config.port}/notify"
  end
else
  AfterConfiguration do |config|
    install_fixture_gems
  end

  Before do
    Docker.compose_project_name = "#{rand.to_s}:#{Time.new.strftime("%s")}"
    Runner.environment.clear
    Runner.environment["BUGSNAG_API_KEY"] = $api_key
    Runner.environment["BUGSNAG_ENDPOINT"] = "http://maze-runner:#{MOCK_API_PORT}"
  end
end
