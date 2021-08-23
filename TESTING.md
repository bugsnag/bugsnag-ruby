# Testing the Ruby Bugsnag notifier

## Unit tests

To run locally:

```
bundle install --with test sidekiq --binstubs
bundle exec rake
```

To run within a different environment, set `RUBY_TEST_VERSION` to your desired Ruby version, then run:

```
RUBY_TEST_VERSION=2.6 docker-compose up --build ruby-unit-tests
```

To run the unit tests against JRuby, run:

```
docker-compose up --build jruby-unit-tests
```

## End-to-end tests

These tests are implemented with our notifier testing tool [Maze Runner](https://github.com/bugsnag/maze-runner).

End to end tests are written in cucumber-style `.feature` files, and need Ruby-backed "steps" in order to know what to run. The tests are located in the top level [`features`](/features/) directory.

Maze runner's CLI and the test fixtures are containerised so you'll need Docker (and Docker Compose) to run them.

__Note: only Bugsnag employees can run the end-to-end tests.__ We have dedicated test infrastructure and private BrowserStack credentials which can't be shared outside of the organisation.

##### Authenticating with the private container registry

You'll need to set the credentials for the aws profile in order to access the private docker registry:

```
aws configure --profile=opensource
```

Subsequently you'll need to run the following commmand to authenticate with the registry:

```
aws ecr get-login-password --profile=opensource | docker login --username AWS --password-stdin 855461928731.dkr.ecr.us-west-1.amazonaws.com
```

__Your session will periodically expire__, so you'll need to run this command to re-authenticate when that happens.

### Running the end to end tests

Once registered with the remote repository, build the test container:

```
docker-compose build ruby-maze-runner
```

Configure the tests to be run in the following way:

- Determine the Ruby version to be tested using the environment variable `RUBY_TEST_VERSION` e.g. `RUBY_TEST_VERSION=2.6`
- If testing rails, set the rails version to be tested using the environment variable `RAILS_VERSION` e.g. `RAILS_VERSION=3`
- If testing sidekiq, set the version to be tested using the environment variable `SIDEKIQ_VERSION`,  e.g. `SIDEKIQ_VERSION=2`

When running the end-to-end tests, you'll want to restrict the feature files run to the specific test features for the platform.  This is done using the Cucumber CLI syntax at the end of the `docker-compose run ruby-maze-runner` command, i.e:

```
RUBY_TEST_VERSION=2.6 RAILS_VERSION=6 docker-compose run --use-aliases ruby-maze-runner features/rails_features --tags "@rails6"
```

- Plain ruby tests should target `features/plain_features`
- Sidekiq tests should target `features/sidekiq.feature`
- Delayed job tests should target `features/delayed_job.feature`
- Rails test should target `features/rails_features`. In addition, the tag syntax should be used to specify which of the scenarios within those files are run.  For example rails 3 test should feature the tag `"@rails3"`

In order to target specific features the exact `.feature` file can be specified, i.e:

```
RUBY_TEST_VERSION=2.6 RAILS_VERSION=6 docker-compose run --use-aliases ruby-maze-runner features/rails_features/app_version.feature --tags "@rails6"
```

In order to avoid running flakey or unfinished tests, the tag `"not @wip"` can be added to the tags option. This is recommended for all CI runs. If a tag is already specified, this should be added using the `and` keyword, e.g. `--tags "@rails6 and not @wip"`

## Manually testing queue libraries

To help manually test queue libraries and Active Job with various queue adapters, you can use [the `run-ruby-integrations` script](./features/fixtures/run-ruby-integrations). This takes care of installing your local copy of Bugsnag, booting Rails, setting up the database and booting the queue library

As with the end-to-end tests, only Bugsnag employees can run this script as it relies on the same private resources

The script will default to booting Sidekiq:

```
# run the rails_integrations fixture with sidekiq
$ ./features/fixtures/run-rails-integrations
```

The script can also run Resque, Que or Delayed Job:

```
$ ./features/fixtures/run-rails-integrations resque
$ ./features/fixtures/run-rails-integrations que
$ ./features/fixtures/run-rails-integrations delayed_job
```
