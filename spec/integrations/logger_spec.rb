require 'spec_helper'

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
        Bundler.with_clean_env do
          pid = Process.spawn('bundle install',
                              out: out_writer.fileno,
                              err: out_writer.fileno)
          Process.waitpid(pid, 0)
          pid = Process.spawn(@env, 'bundle exec rackup config.ru',
                              out: out_writer.fileno,
                              err: out_writer.fileno)
          sleep(2)
          Process.kill(1, pid)
        end
      end
      out_writer.close
      output = ""
      output << out_reader.gets until out_reader.eof?
      output
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

    context 'sets an invalid API key using the BUGSNAG_API_KEY env var' do
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
        Bundler.with_clean_env do
          IO.popen([@env, 'bundle', 'exec', 'ruby', "#{name}.rb", err: [:child, :out]]) do |io|
            output << io.read
          end
        end
      end
      output
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
