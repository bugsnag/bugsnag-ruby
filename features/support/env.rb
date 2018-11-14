require 'fileutils'

Before do
  find_default_docker_compose
end

def output_logs
  $docker_services.each do |service|
    logged_service = service[:service] == :all ? '' : service[:service]
    command = "logs -t #{logged_service}"
    begin
      response = run_docker_compose_command(service[:file], command)
    rescue => exception
      response = "Couldn't retreive logs for #{service[:file]}:#{logged_service}"
    end
    STDOUT.puts response.is_a?(String) ? response : response.to_a
  end
end

def install_fixture_gems
  gem_dir = File.expand_path('../../../', __FILE__)
  Dir.chdir(gem_dir) do
    `rm bugsnag-*.gem` unless Dir.glob('bugsnag-*.gem').empty?
    `gem build bugsnag.gemspec`
    Dir.entries('features/fixtures').reject { |entry| ['.', '..'].include?(entry) }.each do |entry|
      target_dir = "features/fixtures/#{entry}"
      if File.directory?(target_dir)
        `cp bugsnag-*.gem #{target_dir}`
        `gem unpack #{target_dir}/bugsnag-*.gem --target #{target_dir}/temp-bugsnag-lib`
      end
    end
    `rm bugsnag-*.gem`
  end
end

def remove_installed_gems
  removal_targets = ['temp-bugsnag-lib', 'bugsnag-*.gem']
  Dir.entries('features/fixtures').reject { |entry| ['.', '..'].include?(entry) }.each do |entry|
    target_dir = "features/fixtures/#{entry}"
    target_entries = []
    removal_targets.each do |r_target|
      target_entries += Dir.glob("#{target_dir}/#{r_target}")
    end
    target_entries.each do |d_target|
      FileUtils.rm_rf(d_target)
    end
  end
end

at_exit do
  remove_installed_gems
end

install_fixture_gems
