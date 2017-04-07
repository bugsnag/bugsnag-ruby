## Que example

A small app demonstrating reporting an error to Bugsnag from a Que job.

### Running the app

The included application has a single job which updates a user record if no
error occurs (comment out the `raise` to see the intended effect).

* Install the dependencies: `bundle install`
* Set the `DBNAME` environment variable to the name of the database to use
  (otherwise the postgresql default will be used)
* Migrate the database: `bundle exec rake db:migrate`
* Enqueue a job: `bundle exec rake job:enqueue`
* Start a worker: `bundle exec rake job:work`
