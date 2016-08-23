# Bugsnag Sinatra demo

This Sinatra application demonstrates how to use Bugsnag with Sinatra. Before
testing it, open up the `config.ru` file (or any other file with your
configuration details) and configure your API key.

```
Bugsnag.configure do |config|
  config.api_key = '0a6f5add590596f93a8d601ea89af841'
end
```

The other way to configure the API key is to export the `BUGSNAG_API_KEY`
environment variable.

In the same file activate the Bugsnag Rack middleware.

```
use Bugsnag::Rack
```

Be sure that `raise_errors` is set to `true` and `show_exceptions` is set to
`false`. Otherwise, in the development environment, automatic notifications
won't work, as Sinatra would be swallowing exceptions from Bugsnag.

```
set :raise_errors, true
set :show_exceptions, false
```

If you would like to use custom error handlers, then you need to notify Bugsnag
explicitly.

```
error 500 do
  Bugsnag.notify($!) do |report|
    report.severity = "error"
  end
  erb :'errors/500'
end
```

Install dependencies.

```
bundle install
```

Launch the Sinatra application.

```
bundle exec rackup
```

Next, open your project's dashboard on Bugsnag.

1. [crash](http://localhost:9292/crash)
<br/>
Crashes the application and sends a notification about the nature of the crash.
Basically, almost any unhandled exception sends a notification to Bugsnag. See
the line mentioning `get '/crash'`.

1. [crash and use callbacks](http://localhost:9292/crash_with_callback)
<br/>
Before crashing, the application would append the Diagnostics tab with some
predefined information, attached by means of a callback. See the line mentioning
`get '/crash_with_callback'`.

1. [notify](http://localhost:9292/notify)
<br/>
Bugsnag Ruby provides a way to send notifications on demand by means of
`Bugsnag.notify`. This API allows to send notifications manually, without
crashing your application. See the line mentioning `get '/notify'`.

1. [notify with meta data](http://localhost:9292/notify_meta)
<br/>
Same as `notify`, but also attaches meta data. The meta data is any additional
information you want to attach to an exception. In this artificial case
additional information with be sent and displayed in a new tab called
"Diagnostics". See the line mentioning `get '/notify_meta'`.

1. [severity](http://localhost:9292/severity)
<br/>
Bugsnag supports three severities: 'error', 'warning' and 'info'. You can set
the severity by passing one of these objects as a string to '#notify'. See the
line mentioning `get '/severity'`.
