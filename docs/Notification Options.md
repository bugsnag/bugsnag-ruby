# `bugsnag-ruby` Notification Options

It is often useful to send additional meta-data about your app, such as
information about the currently logged in user, along with any
exceptions, to help debug problems.

* [Notification Object](#notification-object)
    - [Instance Methods](#instance-methods)
    - [`Bugsnag::MetaData` Exception Mixin](#exception-mixin)
* [Handled Notification Options](#handled-notification-options)
* [Framework-specific Configuration](#framework-specific-configuration)
    - [Rails Apps](#rails-apps)
    - [Rails API Apps](#rails-api-apps)
    - [Other Ruby Apps](#other-ruby-apps)

## Notification Object

The notification object is passed to all [before bugsnag notify](#sending-custom-data-with-exceptions)
callbacks and is used to manipulate the error report before it is transmitted.

### Instance Methods

#### `add_tab`

Call add_tab on a notification object to add a tab to the error report so that
it would appear on your dashboard.

```ruby
notif.add_tab(:user_info, {
      name: current_user.name
})
```

The first parameter is the tab name that will appear in the error report and the
second is the key, value list that will be displayed in the tab.

#### `remove_tab`

Removes a tab completely from the error report

```ruby
notif.remove_tab(:request)
```

#### `ignore!`

Calling ignore! on a notification object will cause the notification to not be
sent to bugsnag. This means that you can choose dynamically not to send an error
depending on application state or the error itself.

```ruby
notif.ignore! if foo == 'bar'
```

#### `grouping_hash`

Sets the grouping hash of the error report. All errors with the same grouping
hash are grouped together. This is an advanced usage of the library and
mis-using it will cause your errors not to group properly in your dashboard.

```ruby
notif.grouping_hash = "#{exception.message}#{exception.class}"
```

#### `severity`

Set the severity of the error. Severity can be `error`, `warning` or `info`.

```ruby
notif.severity = "error"
```

#### `context`

Set the context of the error report. This is notionally the location of the
error and should be populated automatically. Context is displayed in the
dashboard prominently.

```ruby
notif.context = "billing"
```

#### `user`

You can set or read the user with the user property of the notification. The
user will be a hash of `email`, `id` and `name`.

```ruby
notif.user = {
      id: current_user.id,
        email: current_user.email,
          name: current_user.name
}
```

#### `exceptions`

Allows you to read the exceptions that will be combined into the report.

```ruby
puts "#{notif.exceptions.first.message} found!"
```

#### `meta_data`

Provides access to the meta_data in the error report.

```ruby
notif.ignore! if notif.meta_data[:sidekiq][:retry_count] > 2
```

### Exception Mixin

If you include the `Bugsnag::MetaData` module into your own exceptions, you can
associate meta data with a particular exception.

```ruby
class MyCustomException < Exception
  include Bugsnag::MetaData
end

exception = MyCustomException.new("It broke!")
exception.bugsnag_meta_data = {
  :user_info => {
    name: current_user.name
  }
}

raise exception
```

## Handled Notification Options

Non-fatal exception notifications can send additional metadata in when being
sent via `Bugsnag.notify` including setting the severity and custom data.

#### Severity

You can set the severity of an error in Bugsnag by including the severity option when
notifying bugsnag of the error,

```ruby
Bugsnag.notify(RuntimeError.new("Something broke"), {
  :severity => "error",
})
```

Valid severities are `error`, `warning` and `info`.

Severity is displayed in the dashboard and can be used to filter the error list.
By default all crashes (or unhandled exceptions) are set to `error` and all
`Bugsnag.notify` calls default to `warning`.

#### Multiple projects

If you want to divide errors into multiple Bugsnag projects, you can specify the API key as a parameter to `Bugsnag.notify`:

```ruby
rescue => e
  Bugsnag.notify e, api_key: "your-api-key-here"
end
```

#### Custom Metadata

You can also send additional meta-data with your exception:

```ruby
Bugsnag.notify(RuntimeError.new("Something broke"), {
  :user => {
    :username => "bob-hoskins",
    :registered_user => true
  }
})
```

#### Custom Grouping via `grouping_hash`

If you want to override Bugsnag's grouping algorithm, you can specify a grouping hash key as a parameter to `Bugsnag.notify`:

```ruby
rescue => e
  Bugsnag.notify e, grouping_hash: "this-is-my-grouping-hash"
end
```

All errors with the same groupingHash will be grouped together within the bugsnag dashboard.

## Framework-specific Configuration

### Rails Apps

By default Bugsnag includes some information automatically. For example, we
send all the HTTP headers for requests. Additionally if you're using Warden or
Devise, the id, name and email of the current user are sent.

To send additional information, in any rails controller you can define a
`before_bugsnag_notify` callback, which allows you to add this additional data
by calling `add_tab` on the exception notification object. Please see the
[Notification Object](#notification-object) for details on the notification
parameter.

```ruby
class MyController < ApplicationController
  # Define the filter
  before_bugsnag_notify :add_user_info_to_bugsnag

  # Your controller code here

  private
  def add_user_info_to_bugsnag(notif)
    # Set the user that this bug affected
    # Email, name and id are searchable on bugsnag.com
    notif.user = {
      email: current_user.email,
      name: current_user.name,
      id: current_user.id
    }

    # Add some app-specific data which will be displayed on a custom
    # "Diagnostics" tab on each error page on bugsnag.com
    notif.add_tab(:diagnostics, {
      product: current_product.name
    })
  end
end
```

### Rails API Apps

If you are building an API using the
[rails-api](https://github.com/rails-api/rails-api) gem, your controllers will
inherit from `ActionController::API` instead of `ActionController::Base`.

In this case, the `before_bugsnag_notify` filter will not be automatically
available in your controllers.  In order to use it, you will need to include
the module `Bugsnag::Rails::ControllerMethods`.

```ruby
class ApplicationController < ActionController::API

  # Include module which defines the before_bugsnag_notify filter
  include Bugsnag::Rails::ControllerMethods

  # Other code here
end
```

### Other Ruby Apps

In other ruby apps, you can provide lambda functions to execute before any
`Bugsnag.notify` calls as follows. Don't forget to clear the callbacks at the
end of each request or session. In Rack applications like Sinatra, this is
automatically done for you.

```ruby
# Set a before notify callback
Bugsnag.before_notify_callbacks << lambda {|notif|
  notif.add_tab(:user_info, {
    name: current_user.name
  })
}

# Your app code here

# Clear the callbacks
Bugsnag.before_notify_callbacks.clear
```

