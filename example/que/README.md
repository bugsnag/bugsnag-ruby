# Using Bugsnag with Que

This example shows how to use Bugsnag in conjunction with Que to report any exceptions that occur in your applications.

First, install dependencies
```shell
bundle install
```

## Setting up a database
Que requires a database backend in order to queue jobs.  By default this database will be PostgreSQL although this can be changed via options as detailed in [the que documentation](https://github.com/chanks/que).

Once PostgreSQL is set up as detailed using [the PostgreSQL documentation](https://www.postgresql.org/docs/), ensure Que can connect correctly by setting the environment variable `DBNAME` to the name of an existing PostgreSQL database.

## Configuring Bugsnag with Que

Bugsnag can be configured in one of two ways in your Que app:

1. require `bugsnag` in your application and call `Bugsnag.configure` with a block, setting the appropriate configuration options:
```ruby
Bugsnag.configure do |config|
    config.api_key = "YOUR_API_KEY"
end
```

2. require `bugsnag` in your application and input configuration options through environment variables, such as setting `BUGSNAG_API_KEY` to `YOUR_API_KEY`.

All configuration options can be found in the [Bugsnag documentation](https://docs.bugsnag.com/platforms/ruby/other/configuration-options/)

## Running the example

Run the database migration using rake:
```shell
bundle exec rake migrate:up
```

After this is complete, queue up our test job:
```shell
bundle exec rake job:enqueue
```

Then execute the worker and see the errors appear on the [Bugsnag dashboard](https://app.bugsnag.com):
```shell
bundle exec rake job:work
```
