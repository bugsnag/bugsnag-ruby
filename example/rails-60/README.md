# Bugsnag Rails v6.0 demo

This Rails application demonstrates how to use Bugsnag with Rails v6.0, as well as integrating it into Sidekiq, Que, and Resque.
Further details about integrating Bugsnag with Rails applications can be found [here.](https://docs.bugsnag.com/platforms/ruby/rails/)

Install dependencies

```shell
bundle install
```

Install local binaries (if needed):

```shell
bundle exec rake app:update:bin
```

## Rails v6.0

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

Once the server is running, head to the default path for more information on Bugsnag logging examples.

## Sidekiq in Rails

Sidekiq requires a datastore to run, this example uses [redis](https://redis.io/), installation instructions for which can be found [here](https://redis.io/topics/quickstart) and an official docker image can be found [here](https://hub.docker.com/_/redis/).

### Configuration

Once the configuration has been added to the Rails environment there is no need to further configure Sidekiq.

### Running the examples

Start the Rails server as mentioned above.

Navigate to the `/sidekiq` page and run any of the examples using the links provided.

The worker code can be found in `app/workers/sidekiq_workers.rb`.

To process the jobs, run Sidekiq using the following command:

```shell
bundle exec sidekiq
```

## Que in Rails

Que requires a database backend in order to queue jobs.  By default this database will be PostgreSQL although this can be changed via options as detailed in [the que documentation](https://github.com/chanks/que).

Once PostgreSQL is set up as detailed using [the PostgreSQL documentation](https://www.postgresql.org/docs/), ensure Que can connect correctly before running any of the following examples which reference a `quedb` that can be created with the following command:

```shell
createdb quedb
```

You can configure your connection in the `config/database.yml` file.

### Configuration

All tasks run with Que should set the rails environment to `que`.  This ensures that the correct database and connection settings are used.
Do this by prepending `RAILS_ENV=que` before each command, or run:

```shell
export RAILS_ENV=que
```

Ensure that the initial Que setup is complete by running:

```shell
bundle exec bin/rails generate que:install
```

and

```shell
bundle exec bin/rake db:migrate
```

Further configuration will be taken from the Rails environment.

### Running the examples

Start the Rails server as mentioned above.

Navigate to the `/que` page and queue jobs for any of the examples using links provided.

To process the jobs, run Que using the cli command:

```shell
bundle exec que ./config/environment.rb
```

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
