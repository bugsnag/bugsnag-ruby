# Bugsnag Rails v5.1 demo

This Rails application demonstrates how to use Bugsnag with Rails v5.1, as well as integrating it into Sidekiq, Que, and Resque.
Further details about integrating Bugsnag with Rails applications can be found [here.](https://docs.bugsnag.com/platforms/ruby/rails/)

Install dependencies

```shell
bundle install
```

Install local binaries (if needed):

```shell
bundle exec rake app:update:bin
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

Sidekiq requires a datastore to run, this example uses [redis](https://redis.io/), installation instructions for which can be found [here](https://redis.io/topics/quickstart) and an official docker image can be found [here](https://hub.docker.com/_/redis/).

### Configuration

Once the configuration has been added to the Rails environment there is no need to further configure Sidekiq.

### Running the examples

Start the Rails server as mentioned above.

Navigate to the `/sidekiq` page and run any of the examples using the links provided.

The worker code can be found in `app/workers/sidekiq_workers.rb`.

## Que in Rails


## Resque in Rails

Resque requires a datastore to run, this example uses [redis](https://redis.io/), installation instructions for which can be found [here](https://redis.io/topics/quickstart) and an official docker image can be found [here](https://hub.docker.com/_/redis/).

### Configuration

Resque can be configured by using the Rails environment by making sure it depends on the `environment` task.  This can be achieved when running the worker:

```shell
QUEUE=crash bundle exec rake environment resque:work
```

Or by creating a task, `resque:setup`, that depends on the `environment` task.  An example of this can be found in `lib/tasks/resque:setup.rake`.

### Running the examples

Start the Rails server as mentioned above.

Navigate to the `/resque` page and queue any of the examples using links provided.

To process the queues, run the `resque:work` task as stated in the example webpage. In order to process any of the queues on a single thread start the resque worker using the command:

```shell
QUEUE=crash,callback,metadata bundle exec rake resque:work
```