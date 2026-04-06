require 'spec_helper'
require 'timeout'

describe 'Configuration.logger' do

  before do
    @env = {}
  end

  context 'in a Rails app' do
    key_warning = '[Bugsnag]: No valid API key has been set, notifications will not be sent'
    is_jruby = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
    incompatible = (RUBY_VERSION < '2.0.0') || is_jruby

    before do
      skip "Incompatible with Ruby <2.0 and JRuby" if incompatible
      @env['RACK_ENV'] = 'production'
    end

    def run_app(name)
      out_reader, out_writer = IO.pipe
      Dir.chdir(File.join(File.dirname(__FILE__), "../fixtures/apps/#{name}")) do
        # Determine which Bundler env method to use based on availability
        # Ruby 4.0+ uses with_unbundled_env, Ruby 2-3.x uses with_clean_env, Ruby 1.9.2 has no env isolation
        if Bundler.respond_to?(:with_unbundled_env)
          Bundler.with_unbundled_env do
            execute_bundle_and_app(out_writer)
          end
        elsif Bundler.respond_to?(:with_clean_env)
          Bundler.with_clean_env do
            execute_bundle_and_app(out_writer)
          end
        else
          # Ruby 1.9.2: No env isolation available
          execute_bundle_and_app(out_writer)
        end
      end
      out_writer.close
      output = ""
      output << out_reader.gets until out_reader.eof?
      output
    end

    private

    def execute_bundle_and_app(out_writer)
      # Handle Bundler install for different Ruby versions
      ruby_version = Gem::Version.new(RUBY_VERSION.dup)
      
      if ruby_version >= Gem::Version.new('3.4')
        # Ruby 3.4+: New Bundler syntax with separate steps
        pid = Process.spawn('bundle config set with "test"',
                            out: out_writer.fileno,
                            err: out_writer.fileno)
        Process.waitpid(pid, 0)
        pid = Process.spawn('bundle install',
                            out: out_writer.fileno,
                            err: out_writer.fileno)
        Process.waitpid(pid, 0)
        pid = Process.spawn('bundle binstubs --all',
                            out: out_writer.fileno,
                            err: out_writer.fileno)
        Process.waitpid(pid, 0)
      else
        # Ruby < 3.4: Legacy Bundler syntax (works for 1.9.2+)
        pid = Process.spawn('bundle install --with test --binstubs',
                            out: out_writer.fileno,
                            err: out_writer.fileno)
        Process.waitpid(pid, 0)
      end

      # Run the Rails app
      pid = Process.spawn(@env, 'bundle exec rackup config.ru',
                          out: out_writer.fileno,
                          err: out_writer.fileno)
      sleep(2)
      Process.kill('TERM', pid)
      begin
        # Wait up to 5 seconds for the process to exit
        Timeout.timeout(5) { Process.waitpid(pid) }
      rescue Timeout::Error
        # If still running, force kill
        Process.kill('KILL', pid) rescue nil
        Process.waitpid(pid) rescue nil
      rescue Errno::ECHILD
        # Already exited
      end
    end
    context 'sets an API key using the BUGSNAG_API_KEY env var' do
      it 'does not log a warning' do
        skip "Incompatible with Ruby <2.0 and JRuby" if incompatible
        @env['BUGSNAG_API_KEY'] = 'c34a2472bd240ac0ab0f52715bbdc05d'
        output = run_app('rails-no-config')
        expect(output).not_to include(key_warning)
      end
    end

    context 'sets an API key using the bugsnag initializer' do
      it 'does not log a warning' do
        skip "Incompatible with Ruby <2.0 and JRuby" if incompatible
        output = run_app('rails-initializer-config')
        expect(output).not_to include(key_warning)
      end
    end

    context 'skips setting an API key' do
      it 'logs a warning' do
        skip "Incompatible with Ruby <2.0 and JRuby" if incompatible
        output = run_app('rails-no-config')
        expect(output).to include(key_warning)
      end
    end

    context 'when the API key is invalid in the bugsnag initializer' do
      it 'logs a warning' do
        skip "Incompatible with Ruby <2.0 and JRuby" if incompatible
        output = run_app('rails-invalid-initializer-config')
        expect(output).to include(key_warning)
      end
    end

    context 'sets an invalid API key using the BUGSNAG_API_KEY env var' do
      it 'logs a warning' do
        skip "Incompatible with Ruby <2.0 and JRuby" if incompatible
        @env['BUGSNAG_API_KEY'] = 'not a real key'
        output = run_app('rails-no-config')
        expect(output).to include(key_warning)
      end
    end
  end

  context 'in a script' do
    key_warning = /\[Bugsnag\] .* No valid API key has been set, notifications will not be sent/
    
    def run_app(name)
      output = ''
      Dir.chdir(File.join(File.dirname(__FILE__), "../fixtures/apps/scripts")) do
        # Determine which Bundler env method to use based on availability
        # Ruby 4.0+ uses with_unbundled_env, Ruby 2-3.x uses with_clean_env, Ruby 1.9.2 has no env isolation
        if Bundler.respond_to?(:with_unbundled_env)
          Bundler.with_unbundled_env do
            execute_script(name, output)
          end
        elsif Bundler.respond_to?(:with_clean_env)
          Bundler.with_clean_env do
            execute_script(name, output)
          end
        else
          # Ruby 1.9.2: No env isolation available
          execute_script(name, output)
        end
      end
      output
    end

    private

    def execute_script(name, output)
      if RUBY_VERSION < '2.0.0'
        # Ruby 1.9.x: Use shell string with environment variables
        env_str = @env.map { |k, v| "#{k}='#{v}'" }.join(' ')
        IO.popen("#{env_str} bundle exec ruby #{name}.rb 2>&1") do |io|
          output << io.read
        end
      else
        # Ruby 2.0+: Use array form with env hash and stderr redirection
        IO.popen([@env, 'bundle', 'exec', 'ruby', "#{name}.rb", err: [:child, :out]]) do |io|
          output << io.read
        end
      end
    end

    context 'sets an API key using the BUGSNAG_API_KEY env var' do
      it 'does not log a warning' do
        @env['BUGSNAG_API_KEY'] = 'c34a2472bd240ac0ab0f52715bbdc05d'
        output = run_app('no_config')
        expect(output).not_to match(key_warning)
      end
    end

    context 'sets an API key using Bugsnag.configure' do
      it 'does not log a warning' do
        output = run_app('configure_key')
        expect(output).not_to match(key_warning)
      end
    end

    context 'sets an invalid API key using Bugsnag.configure' do
      it 'logs a warning' do
        output = run_app('configure_invalid_key')
        expect(output).to match(key_warning)
      end
    end

    context 'sets an invalid API key using the BUGSNAG_API_KEY env var' do
      it 'logs a warning' do
        @env['BUGSNAG_API_KEY'] = 'bad key bad key whatcha gonna do'
        output = run_app('no_config')
        expect(output).to match(key_warning)
      end
    end

    context 'skips setting an API key' do
      it 'logs a warning' do
        output = run_app('no_config')
        expect(output).to match(key_warning)
      end
    end
  end
end
