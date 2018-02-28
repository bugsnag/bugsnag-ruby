# Bugsnag Rails v5.1 demo

This Rails application demonstrates how to use Bugsnag with Rails v5.1, as well as integrating it into Sidekiq, Que, and Resque.
Further details about integrating Bugsnag with Rails applications can be found [here.](https://docs.bugsnag.com/platforms/ruby/rails/)

Install dependencies

```shell
bundle install
```

## Rails v5.1

### Configuration

There are two methods of configuring Bugsnag within a Rails application:

1. Your `API_KEY` can be exported as an environment variable `BUGSNAG_API_KEY`.

2. Generate a bugsnag configuration file at ```config/initializers/bugsnag.rb``` which can be populated with the [available configuration options](https://docs.bugsnag.com/platforms/ruby/rails/configuration-options/) by running the rails command:
  ```shell
  bundle exec bin/rails generate bugsnag YOUR_API_KEY_HERE
  ```

This is sufficient to start reporting unhandled exceptions to Bugsnag.

### Running the example

Run the example using:

```shell
bundle exec bin/rails server
```

Once the server is running head to the default path for more information on Bugsnag logging examples.

## Sidekiq in Rails



## Que in Rails

## Resque in Rails