# Bugsnag Rails v4.2 demo (with delayed_job)

This Rails application demonstrates how to use Bugsnag with Rails v4.2.
Further details about integrating Bugsnag with Rack applications can be found [here.](https://docs.bugsnag.com/platforms/ruby/rails/)

Install dependencies

```shell
bundle install
```

## Configuring Bugsnag and Rails v4.2

There are two methods of configuring Bugsnag within a Rails application:

1. Your `API_KEY` can be exported as an environment variable `BUGSNAG_API_KEY`.

2. Generate a bugsnag configuration file at ```config/initializers/bugsnag.rb``` which can be populated with the [available configuration options](https://docs.bugsnag.com/platforms/ruby/rails/configuration-options/) by running the rails command:
  ```shell
  rails generate bugsnag YOUR_API_KEY_HERE
  ```

This is sufficient to start reporting unhandled exceptions to Bugsnag.


## Running the example

Run the example using:

```shell
bundle exec rails server
```

Once the server is running head to the default path for more information on Bugsnag logging examples.

# Running delayed job

To run the delayed job example you'll need to first run a database migration:
```shell
bundle exec rake db:migrate
```

This example comes packaged with a delayed job setup to demonstrate how errors are reported through delayed job.  Once the rails setup is complete with an initializer at ```config/initializers/bugsnag.rb``` you don't need to do anything else with delayed job, just run the examples!

The examples can be found at ```app/helpers/test_delayed_job_helper```

In order to run the delayed job example:

1. Open the rails console using the command:
```shell
bundle exec bin/rails console
```

2. Queue up the examples you wish to run.  At the moment there are two examples `crash` and `notify`, which are queued by passing the symbol to the `helper.test_dj` like:
```ruby
helper.test_dj :crash
helper.test_dj :notify
```

3. Exit the rails console using the `exit` command.
4. Run the queue using rake:
```shell
bundle exec rake jobs:work
```
