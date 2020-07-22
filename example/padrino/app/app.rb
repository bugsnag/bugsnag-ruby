module BugsnagPadrino
  class App < Padrino::Application
    register Padrino::Mailer
    register Padrino::Helpers

    enable :sessions

    ##
    # Caching support.
    #
    # register Padrino::Cache
    # enable :caching
    #
    # You can customize caching store engines:
    #
    # set :cache, Padrino::Cache.new(:LRUHash) # Keeps cached values in memory
    # set :cache, Padrino::Cache.new(:Memcached) # Uses default server at localhost
    # set :cache, Padrino::Cache.new(:Memcached, '127.0.0.1:11211', :exception_retry_limit => 1)
    # set :cache, Padrino::Cache.new(:Memcached, :backend => memcached_or_dalli_instance)
    # set :cache, Padrino::Cache.new(:Redis) # Uses default server at localhost
    # set :cache, Padrino::Cache.new(:Redis, :host => '127.0.0.1', :port => 6379, :db => 0)
    # set :cache, Padrino::Cache.new(:Redis, :backend => redis_instance)
    # set :cache, Padrino::Cache.new(:Mongo) # Uses default server at localhost
    # set :cache, Padrino::Cache.new(:Mongo, :backend => mongo_client_instance)
    # set :cache, Padrino::Cache.new(:File, :dir => Padrino.root('tmp', app_name.to_s, 'cache')) # default choice
    #

    ##
    # Application configuration options.
    #
    set :raise_errors, true         # Raise exceptions (will stop application) (default for test)
    # set :dump_errors, true        # Exception backtraces are written to STDERR (default for production/development)
    set :show_exceptions, false     # Shows a stack trace in browser (default for development)
    # set :logging, true            # Logging in STDOUT for development and file for production (default only for development)
    # set :public_folder, 'foo/bar' # Location for static assets (default root/public)
    # set :reload, false            # Reload application files (default in development)
    # set :default_builder, 'foo'   # Set a custom form builder (default 'StandardFormBuilder')
    # set :locale_path, 'bar'       # Set path for I18n translations (default your_apps_root_path/locale)
    # disable :sessions             # Disabled sessions by default (enable if needed)
    # disable :flash                # Disables sinatra-flash (enabled by default if Sinatra::Flash is defined)
    # layout  :my_layout            # Layout can be in views/layouts/foo.ext or views/foo.ext (default :application)
    #

    ##
    # You can configure for a specified environment like:
    #
    #   configure :development do
    #     set :foo, :bar
    #     disable :asset_stamp # no asset timestamping for dev
    #   end
    #

    ##
    # You can manage errors like:
    #
    #   error 404 do
    #     render 'errors/404'
    #   end
    #
    #   error 505 do
    #     render 'errors/505'
    #   end
    #

    get '/' do
      opts = {
        fenced_code_blocks: true
      }
      renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML, opts)
      renderer.render(File.read(File.expand_path('app/templates/index.md')))
    end

    get '/crash' do
      raise RuntimeError.new('Bugsnag Padrino demo says: It crashed! Go check ' +
        'bugsnag.com for a new notification!')
    end

    get '/notify' do
      Bugsnag.notify(RuntimeError.new("Bugsnag Padrino demo says: False alarm, your application didn't crash"))

      "Bugsnag Padrino demo says: It didn't crash! " +
        'But still go check <a href="https://bugsnag.com">https://bugsnag.com</a>' +
        ' for a new notification.'
    end

    get '/notify_data' do
      error = RuntimeError.new("Bugsnag Padrino demo says: False alarm, your application didn't crash")
      Bugsnag.notify(error) do |report|
        report.add_tab(:diagnostics, {
          message: 'Padrino demo says: Everything is great',
          code: 200
        })
      end

      "Bugsnag Padrino demo says: It didn't crash! " +
        'But still go check <a href="https://bugsnag.com">https://bugsnag.com</a>' +
        ' for a new notification. Check out the Diagnostics tab for the meta data'
    end

    get '/notify_severity' do
      msg = "Bugsnag Padrino demo says: Look at the circle on the right side. It's different"
      error = RuntimeError.new(msg)
      Bugsnag.notify error do |report|
        report.severity = 'info'
      end
      msg
    end
  end
end
