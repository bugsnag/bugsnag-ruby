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

AfterConfiguration do |config|
  install_fixture_gems
end

class RunnerEnvironment < Hash
  # Override Hash#clear with a version that keeps the API key and endpoint
  # These are set before every test anyway, so there's no need to get rid of them
  def clear
    self.keep_if do |key, value|
      key == "BUGSNAG_API_KEY" || key == "BUGSNAG_ENDPOINT"
    end
  end
end

Before do
  # FIXME: This is a hack to work around a Maze Runner bug!
  # Maze Runner now clears the environment between tests automatically, but this
  # happens _after_ this Before block runs. Therefore the API key and endpoint
  # that we set here are removed, so all of the tests fail because they can't
  # report anything. Once that issue is resolved, we can remove this and the
  # RunnerEnvironment class
  class Runner
    class << self
      def environment
        @env ||= RunnerEnvironment.new
      end
    end
  end

  Docker.compose_project_name = "#{rand.to_s}:#{Time.new.strftime("%s")}"
  Runner.environment.clear
  Runner.environment["BUGSNAG_API_KEY"] = $api_key
  Runner.environment["BUGSNAG_ENDPOINT"] = "http://maze-runner:#{MOCK_API_PORT}"
end
