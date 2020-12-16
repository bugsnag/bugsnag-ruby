AfterConfiguration do
  raise "Bugsnag.gem not found. Is this running in a docker-container?" unless File.exist?("/app/bugsnag.gem")

  Dir.children('features/fixtures').each do |entry|
    target_dir = "features/fixtures/#{entry}"

    next unless File.directory?(target_dir)

    `cp /app/bugsnag.gem #{target_dir}`
    `gem unpack #{target_dir}/bugsnag.gem --target #{target_dir}/temp-bugsnag-lib`
  end

  MazeRunner.config.receive_no_requests_wait = 5
  MazeRunner.config.enforce_bugsnag_integrity = false
end

MazeRunner.hooks.before do
  Docker.compose_project_name = "#{rand.to_s}:#{Time.new.strftime("%s")}"
  Runner.environment.clear
  Runner.environment["BUGSNAG_API_KEY"] = $api_key
  Runner.environment["BUGSNAG_ENDPOINT"] = "http://maze-runner:#{MOCK_API_PORT}"
end
