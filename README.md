Bugsnag Notifier for Ruby <img src="https://travis-ci.org/bugsnag/bugsnag-ruby.svg?branch=master" alt="build status" class="build-status">
=========================

The Bugsnag Notifier for Ruby gives you instant notification of exceptions
thrown from your **Rails**, **Sinatra**, **Rack** or **plain Ruby** app.
Any uncaught exceptions will trigger a notification to be sent to your
Bugsnag project.

[Bugsnag](http://bugsnag.com) captures errors in real-time from your web,
mobile and desktop applications, helping you to understand and resolve them
as fast as possible. [Create a free account](http://bugsnag.com) to start
capturing exceptions from your applications.


Contents
--------

- [Getting Started](#getting-started)
	- [Installation](#installation)
	- [Rake Integration](#rake-integration)
	- [Sending a Test Notification](#sending-a-test-notification)
- [Usage](#usage)
	- [Catching and Reporting Exceptions](#catching-and-reporting-exceptions)
	- [Sending Non-fatal Exceptions](#sending-non-fatal-exceptions)
	- [Deploy Tracking](#deploy-tracking)
	- [Callbacks](#callbacks)
	- [Configuration](https://github.com/bugsnag/bugsnag-ruby/tree/master/docs/Configuration.md)
	- [Notification Options](https://github.com/bugsnag/bugsnag-ruby/tree/master/docs/Notification Options.md)
- [Demo Applications](#demo-applications)
- [Support](#support)
- [Contributing](#contributing)
- [License](#license)


Getting Started
---------------


### Installation

1.  Add the `bugsnag` gem to your `Gemfile`

    ```ruby
    gem "bugsnag"
    ```

2.  Install the gem

    ```shell
    bundle install
    ```

3. Configure the Bugsnag module with your API key.

    **Rails**: Use our generator

    ```shell
    rails generate bugsnag YOUR_API_KEY_HERE
    ```

    **Other Ruby/Rack/Sinatra apps**: Put this snippet in your initialization.

    ```ruby
    Bugsnag.configure do |config|
      config.api_key = "YOUR_API_KEY_HERE"
    end
    ```

    The Bugsnag module will read the `BUGSNAG_API_KEY` environment variable if
    you do not configure one automatically.

### Rake Integration

Rake integration is automatically enabled in Rails 3/4/5 apps, so providing you
load the environment in your Rake tasks you dont need to do anything to get Rake
support. If you choose not to load your environment, you can manually configure
Bugsnag with a `bugsnag.configure` block in the Rakefile.

Bugsnag can automatically notify of all exceptions that happen in your rake
tasks. In order to enable this, you need to `require "bugsnag/rake"` in your
Rakefile, like so:

```ruby
require File.expand_path('../config/application', __FILE__)
require 'rake'
require "bugsnag/rake"

Bugsnag.configure do |config|
  config.api_key = "YOUR_API_KEY_HERE"
end

YourApp::Application.load_tasks
```

> Note: We also configure Bugsnag in the Rakefile, so the tasks that do not load
> the full environment can still notify Bugsnag.

### Sending a Test Notification

To test that bugsnag is properly configured, you can use the `test_exception`
rake task:

```bash
rake bugsnag:test_exception
```

A test exception will be sent to your bugsnag dashboard if everything is
configured correctly.

Usage
-----

### Catching and Reporting Exceptions

Bugsnag Ruby works out of the box with Rails, Sidekiq, Resque, DelayedJob (3+),
Mailman, Rake and Rack. It should be easy to add support for other frameworks,
either by sending a pull request here or adding a hook to those projects.

#### Rack/Sinatra Apps

Activate the Bugsnag Rack middleware

```ruby
use Bugsnag::Rack
```

**Sinatra**: Note that `raise_errors` must be enabled. If you are
    using custom error handlers, then you will need to notify Bugsnag
    explicitly:

```ruby
error 500 do
  Bugsnag.auto_notify($!)
  erb :"errors/500"
end
```

#### Custom Ruby Scripts

**Custom Ruby Scripts**: If you are running a standard ruby script,
you can ensure that all exceptions are sent to Bugsnag by adding
the following code to your app:

```ruby
at_exit do
  if $!
    Bugsnag.notify($!)
  end
end
```

#### EventMachine Apps

If your app uses [EventMachine](http://rubyeventmachine.com/) you'll need to
manually notify Bugsnag of errors. There are two ways to do this in your
EventMachine apps, first you should implement `EventMachine.error_handler`:

```ruby
EventMachine.error_handler{|e|
  Bugsnag.notify(e)
}
```

If you want more fine-grained error handling, you can use the
[errback](http://eventmachine.rubyforge.org/EventMachine/Deferrable.html#errback-instance_method)
function, for example:

```ruby
EventMachine::run do
  server = EventMachine::start_server('0.0.0.0', PORT, MyServer)
  server.errback {
    EM.defer do
      Bugsnag.notify(RuntimeError.new("Something bad happened"))
    end
  }
end
```

For this to work, include [Deferrable](http://eventmachine.rubyforge.org/EventMachine/Deferrable.html)
in your `MyServer`, then whenever you want to raise an error, call `fail`.

### Sending Non-fatal Exceptions

If you would like to send non-fatal exceptions to Bugsnag, you can call
`Bugsnag.notify`:

```ruby
Bugsnag.notify(RuntimeError.new("Something broke"))
```

Additional data can be sent with exceptions as an options hash as detailed in the [Notification Options](docs/Notification Options.md) documentation, including some [options specific to non-fatal exceptions](docs/Notification Options.md#handled-notification-options).


### Callbacks

The Bugsnag Notifier for Ruby provides its own middleware system, similar to
the one used in Rack applications. Middleware allows you to execute code
before and after an exception is sent to bugsnag.com, so you can do things
such as:

-   Send application-specific information along with exceptions, eg. the name
    of the currently logged in user,
-   Write exception information to your internal logging system.

To make your own middleware, create a class that looks like this:

```ruby
class MyMiddleware
  def initialize(bugsnag)
    @bugsnag = bugsnag
  end

  def call(notification)
    # Your custom "before notify" code

    @bugsnag.call(notification)

    # Your custom "after notify" code
  end
end
```

You can then add your middleware to the middleware stack as follows:

```ruby
Bugsnag.configure do |config|
  config.middleware.use MyMiddleware
end
```

You can also view the order of the currently activated middleware by running `rake bugsnag:middleware`.

Check out Bugsnag's [built in middleware classes](https://github.com/bugsnag/bugsnag-ruby/tree/master/lib/bugsnag/middleware)
for some real examples of middleware in action.


Deploy Tracking
---------------

Bugsnag allows you to track deploys of your apps. By sending the
source revision or application version to bugsnag.com when you deploy a new
version of your app, you'll be able to see which deploy each error was
introduced in.

### Using Heroku

You can easily add Bugsnag deploy tracking to your Heroku application by
running the following command from your application's directory:

```shell
$ bundle exec rake bugsnag:heroku:add_deploy_hook
```

If you have multiple Heroku apps, you can specify which app to add the hook
for as with the `HEROKU_APP` environment variable:

```shell
$ bundle exec rake bugsnag:heroku:add_deploy_hook HEROKU_APP=my-app
```

### Using Capistrano

If you use [capistrano](https://github.com/capistrano/capistrano) to deploy
your apps, you can enable deploy tracking by adding the integration to your
app's `deploy.rb`:

```ruby
require "bugsnag/capistrano"

set :bugsnag_api_key, "api_key_here"
```

### Using Rake

If you aren't using capistrano, you can run the following rake command from
your deploy scripts.

```shell
rake bugsnag:deploy BUGSNAG_REVISION=source-control-revision BUGSNAG_RELEASE_STAGE=production BUGSNAG_API_KEY=api-key-here
```

The bugsnag rake tasks will be automatically available for Rails 3/4
apps, to make the rake tasks available in other apps, add the following to
your `Rakefile`:

```ruby
require "bugsnag/tasks"
```

### Configuring Deploy Tracking

You can set the following environmental variables to override or specify
additional deploy information:

-   **BUGSNAG_API_KEY** -
    Your Bugsnag API key (required).
-   **BUGSNAG_RELEASE_STAGE** -
    The release stage (eg, production, staging) currently being deployed.
    This is set automatically from your Bugsnag settings or rails/rack
    environment.
-   **BUGSNAG_REPOSITORY** -
    The repository from which you are deploying the code. This is set
    automatically if you are using capistrano.
-   **BUGSNAG_BRANCH** -
    The source control branch from which you are deploying the code.
    This is set automatically if you are using capistrano.
-   **BUGSNAG_REVISION** -
    The source control revision for the code you are currently deploying.
    This is set automatically if you are using capistrano.
-   **BUGSNAG_APP_VERSION** -
    The app version of the code you are currently deploying. Only set this
    if you tag your releases with [semantic version numbers](http://semver.org/)
    and deploy infrequently.

For more information, check out the [deploy tracking api](https://bugsnag.com/docs/deploy-tracking-api)
documentation.


Demo Applications
-----------------

[There are demo applications that use the Bugsnag Ruby gem](https://github.com/bugsnag/bugsnag-example-apps/tree/master/apps/ruby):
examples include Rails, Sinatra, Rack, Padrino integrations, etc.


Support
-------

* [Additional Documentation](https://github.com/bugsnag/bugsnag-ruby/tree/master/docs)
* [Search open and closed issues](https://github.com/bugsnag/bugsnag-ruby/issues?utf8=✓&q=is%3Aissue) for similar problems
* [Report a bug or request a feature](https://github.com/bugsnag/bugsnag-ruby/issues/new)


Contributing
------------

We'd love you to file issues and send pull requests. The [contributing guidelines](https://github.com/bugsnag/bugsnag-ruby/CONTRIBUTING.md) details the process of building and testing `bugsnag-ruby`, as well as the pull request process. Feel free to comment on [existing issues](https://github.com/bugsnag/bugsnag-ruby/issues) for clarification or starting points.


License
-------

The Bugsnag ruby notifier is free software released under the MIT License.
See [LICENSE.txt](LICENSE.txt) for details.
