# Bugsnag Padrino demo

This Padrino application demonstrates how to use Bugsnag with Padrino.
Further details about integrating Bugsnag with Rack applications can be found [here.](https://docs.bugsnag.com/platforms/ruby/rack/)

Install dependencies

```shell
bundle install
```

## Configuring Bugsnag and Padrino

1. Set up the Padrino Bugsnag configuration in ```config/boot.rb``` in the `before_load` call according to the [available configuration options](https://docs.bugsnag.com/platforms/ruby/rack/configuration-options/):
  ```ruby
  Padrino.before_load do
    Bugsnag.configure do |config|
      config.api_key = 'YOUR_API_KEY'
    end
  end
  ```

2. Register the Rack middleware in ```config/boot.rb``` in the  `after_load` call:
  ```ruby
  Padrino.after_load do
    Padrino.use Bugsnag::Rack
  end
  ```

3. In `production` automatic notification of exceptions and errors will be enabled by default.  If you want to enable notifications in `development`, open ```app/app.rb``` and set the following options:
```ruby
set :raise_errors, true
set :show_exceptions, false
```

## Running the example

Run the example using:

```shell
bundle exec padrino start
```

Once the server is running head to the default path for more information on Bugsnag logging examples.
