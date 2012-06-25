Official Bugsnag Notifier for Ruby
==================================

The Bugsnag Notifier for Ruby gives you instant notification of exceptions
thrown from your **Rails**, **Sinatra**, **Rack** or **plain Ruby** app.
Any uncaught exceptions will trigger a notification to be sent to your 
Bugsnag project.


What is Bugsnag?
----------------

[Bugsnag](http://bugsnag.com) captures errors in real-time from your web, 
mobile and desktop applications, helping you to understand and resolve them 
as fast as possible. [Create a free account](http://bugsnag.com).


How to Install (Rails)
----------------------

1.  Add the `bugsnag` gem to your `Gemfile`

    ```ruby
    gem "bugsnag"
    ```

2.  Install the gem

    ```shell
    bundle install
    ```

3.  Copy the following code to a new file at `config/initializers/bugsnag.rb`

    ```ruby
    Bugsnag.configure do |config|
      config.api_key = "YOUR_API_KEY_HERE"
    end
    ```

How to Install (Sinatra)
------------------------

```ruby
require "bugsnag"

Bugsnag.configure do |config|
  config.api_key = "YOUR_API_KEY_HERE"
end

use Bugsnag::Rack
```


Send Non-Fatal Exceptions to Bugsnag
------------------------------------

If you would like to send non-fatal exceptions to Bugsnag, there are two 
ways of doing so. From a rails controller, you can call `notify_bugsnag`:

```ruby
notify_bugsnag(RuntimeError.new("Something broke"))
```

You can also send additional meta-data with your exception:

```ruby
notify_bugsnag(RuntimeError.new("Something broke"), {
  :username => "bob-hoskins",
  :registered_user => true
})
```

Anywhere else in your ruby code, you can call `Bugsnag.notify`:

```ruby
Bugsnag.notify(RuntimeError.new("Something broke"));
```


Configuration
-------------

To configure additional Bugsnag settings, use the block syntax and set any
settings you need on the `config` block variable. For example:

```ruby
Bugsnag.configure do |config|
  config.api_key = "your-api-key-here"
  config.use_ssl = true
  config.notify_release_stages = ["production", "development"]
end
```

###api_key

Your Bugsnag API key (required).

```ruby
config.api_key = "your-api-key-here"
```

###release_stage

If you would like to distinguish between errors that happen in different
stages of the application release process (development, production, etc)
you can set the `release_stage` that is reported to Bugsnag.

```ruby
config.release_stage = "development"
```
    
In rails apps this value is automatically set from `RAILS_ENV`, and in rack
apps it is automatically set to `RACK_ENV`. Otherwise the default is 
"production".

###notify_release_stages

By default, we will only notify Bugsnag of exceptions that happen when 
your `release_stage` is set to be "production". If you would like to 
change which release stages notify Bugsnag of exceptions you can
set `notify_release_stages`:
    
```ruby
config.notify_release_stages = ["production", "development"]
```

###auto_notify

By default, we will automatically notify Bugsnag of any fatal exceptions
in your application. If you want to stop this from happening, you can set
`auto_notify`:
    
```ruby
config.auto_notify = false
```

###use_ssl

Enforces all communication with bugsnag.com be made via ssl.

```ruby
config.use_ssl = true
```

By default, `use_ssl` is set to false.

###project_root

We mark stacktrace lines as `inProject` if they come from files inside your
`project_root`. In rails apps this value is automatically set to `RAILS_ROOT`,
otherwise you should set it manually:

```ruby
config.project_root = "/var/www/myproject"
```

###app_version

If you want to track which versions of your application each exception 
happens in, you can set `app_version`. This is set to `nil` by default.

```ruby
config.app_version = "2.5.1"
```

###params_filters

Sets the strings to filter out from the `params` hashes before sending
them to Bugsnag. Use this if you want to ensure you don't send 
sensitive data such as passwords, and credit card numbers to our 
servers. Any keys which contain these strings will be filtered.

```ruby
config.params_filters << "credit_card_number"
```

By default, `params_filters` is set to `["password", "password_confirmation"]`

###ignore_classes

Sets for which exception classes we should not send exceptions to bugsnag.com.

```ruby
config.ignore_classes << "ActiveRecord::StatementInvalid"
```

By default, `ignore_classes` contains the following classes:

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


Reporting Bugs or Feature Requests
----------------------------------

Please report any bugs or feature requests on the github issues page for this
project here:

<https://github.com/bugsnag/bugsnag-ruby/issues>


Contributing
------------
 
-   Check out the latest master to make sure the feature hasn't been 
    implemented or the bug hasn't been fixed yet
-   Check out the issue tracker to make sure someone already hasn't requested
    it and/or contributed it
-   Fork the project
-   Start a feature/bugfix branch
-   Commit and push until you are happy with your contribution
-   Thanks!


License
-------

The Bugsnag ruby notifier is free software released under the MIT License. 
See LICENSE.txt for details.