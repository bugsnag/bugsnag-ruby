# `bugsnag-ruby` Configuration

To configure additional Bugsnag settings, use the block syntax and set any
settings you need on the `config` block variable. For example:

```ruby
Bugsnag.configure do |config|
  config.api_key = "your-api-key-here"
  config.notify_release_stages = ["production", "development"]
end
```

## Available Options

### `api_key`

Your Bugsnag API key (required).

```ruby
config.api_key = "your-api-key-here"
```

### `app_type`

You can set the type of application executing the current code by using
`app_type`:

```ruby
config.app_type = "resque"
```

This is usually used to represent if you are running in a Rails server, Sidekiq
job or Rake task for example. Bugsnag will automatically detect most application
types for you.

### `app_version`

If you want to track in which versions of your application each exception
happens, you can set `app_version`. This is set to `nil` by default.

```ruby
config.app_version = "2.5.1"
```

### `auto_notify`

By default, we will automatically notify Bugsnag of any fatal exceptions
in your application. If you want to stop this from happening, you can set
`auto_notify`:

```ruby
config.auto_notify = false
```

### `endpoint`

By default, we'll send crashes to *notify.bugsnag.com* to display them on
your dashboard. If you are using *Bugsnag Enterprise* you'll need to set
this to be your *Event Server* endpoint, for example:

```ruby
config.endpoint = "bugsnag.example.com:49000"
```

### `ignore_classes`

Sets for which exception classes we should not send exceptions to bugsnag.com.

```ruby
config.ignore_classes << "ActiveRecord::StatementInvalid"
```

You can also provide a lambda function here to ignore by other exception
attributes or by a regex:

```ruby
config.ignore_classes << lambda {|ex| ex.message =~ /timeout/}
```

By default, `ignore_classes` contains the following:

```ruby
[
  "ActiveRecord::RecordNotFound",
  "ActionController::RoutingError",
  "ActionController::InvalidAuthenticityToken",
  "CGI::Session::CookieStore::TamperedWithCookie",
  "ActionController::UnknownAction",
  "AbstractController::ActionNotFound"
]
```

### `ignore_user_agents`

Sets an array of Regexps that can be used to ignore exceptions from
certain user agents.

```ruby
config.ignore_user_agents << %r{Chrome}
```

By default, `ignore_user_agents` is empty, so exceptions caused by all
user agents are reported.

### `logger`

Sets which logger to use for Bugsnag log messages. In rails apps, this is
automatically set to use `Rails.logger`, otherwise it will be set to
`Logger.new(STDOUT)`.

### `middleware`

Provides access to the middleware stack, see the
[Bugsnag Middleware](#bugsnag-middleware) section below for details.

### `notify_release_stages`

By default, we will notify Bugsnag of exceptions that happen in any
`release_stage`. If you would like to change which release stages
notify Bugsnag of exceptions you can set `notify_release_stages`:

```ruby
config.notify_release_stages = ["production", "development"]
```

### `params_filters`

Sets which keys should be filtered out from `params` hashes before sending
them to Bugsnag. Use this if you want to ensure you don't send sensitive data
such as passwords, and credit card numbers to our servers. You can add both
strings and regular expressions to this array. When adding strings, keys which
*contain* the string will be filtered. When adding regular expressions, any
keys which *match* the regular expression will be filtered.

```ruby
config.params_filters += ["credit_card_number", /^password$/]
```

By default, `params_filters` is set to `[/authorization/i, /cookie/i,
/password/i, /secret/i]`, and for rails apps, imports all values from
`Rails.configuration.filter_parameters`.

<!-- Custom anchor for linking from alerts -->
<div id="set-project-root"></div>
### `project_root`

We mark stacktrace lines as `inProject` if they come from files inside your
`project_root`. In rails apps this value is automatically set to `RAILS_ROOT`,
otherwise you should set it manually:

```ruby
config.project_root = "/var/www/myproject"
```

### `proxy_host`

Sets the address of the HTTP proxy that should be used for requests to bugsnag.

```ruby
config.proxy_host = "10.10.10.10"
```

### `proxy_password`

Sets the password for the user that should be used to send requests to the HTTP proxy for requests to bugsnag.

```ruby
config.proxy_password = "proxy_secret_password_here"
```

### `proxy_port`

Sets the port of the HTTP proxy that should be used for requests to bugsnag.

```ruby
config.proxy_port = 1089
```

### `proxy_user`

Sets the user that should be used to send requests to the HTTP proxy for requests to bugsnag.

```ruby
config.proxy_user = "proxy_user"
```

### `release_stage`

If you would like to distinguish between errors that happen in different
stages of the application release process (development, production, etc)
you can set the `release_stage` that is reported to Bugsnag.

```ruby
config.release_stage = "development"
```

In rails apps this value is automatically set from `RAILS_ENV`, and in rack
apps it is automatically set to `RACK_ENV`. Otherwise the default is
"production".

### `send_environment`

Bugsnag can transmit your rack environment to help diagnose issues. This environment
can sometimes contain private information so Bugsnag does not transmit by default. To
send your rack environment, set the `send_environment` option to `true`.

```ruby
config.send_environment = true
```

### `send_code`

Bugsnag automatically sends a small snippet of the code that crashed to help you diagnose
even faster from within your dashboard. If you don't want to send this snippet you can
set the `send_code` option to `false`.

```ruby
config.send_code = false
```

### `timeout`
By default the timeout for posting errors to Bugsnag is 15 seconds, to change this
you can set the `timeout`:

```ruby
config.timeout = 10
```

### `use_ssl`

Enforces all communication with bugsnag.com be made via ssl. You can turn
this off if necessary.

```ruby
config.use_ssl = false
```

By default, `use_ssl` is set to true.

