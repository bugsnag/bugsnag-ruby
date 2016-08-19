# Bugsnag Padrino demo

This Padrino application demonstrates how to use Bugsnag with Padrino. Before
testing it, open up the `config/boot.rb` file configure your API key inside
`Padrino.before_load`.

```
Padrino.before_load do
  Bugsnag.configure do |config|
    config.api_key = '0a6f5add590596f93a8d601ea89af841'
  end
end
```

In the same file activate the Bugsnag Rack middleware.

```
Padrino.after_load do
  Padrino.use Bugsnag::Rack
end
```

Open up `app/app.rb`, find two options and set them as follows: `raise_errors`
to `true` and `show_exceptions` to `false`. This enables automatic notifications
in the development environment. By default Padrino swallows exceptions from
Bugsnag (only in development, though).

```
set :raise_errors, true
set :show_exceptions, false
```

If you would like to use custom error handlers, then you need to notify Bugsnag
explicitly.

```
error 500 do
  Bugsnag.auto_notify($!)
  erb :'errors/500'
end
```

Install dependencies.

```
bundle install
```

Launch the Padrino application.

```
bundle exec padrino start
```

Next, open your project's dashboard on Bugsnag.

1. [crash](http://localhost:9292/crash)
<br/>
Crashes the application and sends a notification about the nature of the crash.
Basically, almost any unhandled exception sends a notification to Bugsnag. See
the line mentioning `get '/crash'` in `app/app.rb`.

1. [crash and use callbacks](http://localhost:9292/crash_with_callback)
<br/>
Before crashing, the application would append the Diagnostics tab with some
predefined information, attached by means of a callback. See the line mentioning
`get '/crash_with_callback'` in `app/app.rb`.

1. [notify](http://localhost:9292/notify)
<br/>
Bugsnag Ruby provides a way to send notifications on demand by means of
`Bugsnag.notify`. This API allows to send notifications manually, without
crashing your application. See the line mentioning `get '/notify'` in
`app/app.rb`.

1. [notify with meta data](http://localhost:9292/notify_meta)
<br/>
Same as `notify`, but also attaches meta data. The meta data is any additional
information you want to attach to an exception. In this artificial case
additional information with be sent and displayed in a new tab called
"Diagnostics". See the line mentioning `get '/notify_meta'` in `app/app.rb`.

1. [severity](http://localhost:9292/severity)
<br/>
Bugsnag supports three severities: 'error', 'warning' and 'info'. You can set
the severity by passing one of these objects as a string to '#notify'. See the
line mentioning `get '/severity'` in `app/app.rb`.
