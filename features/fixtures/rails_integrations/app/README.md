# README

## DelayedJob

- Queue a job with `bin/rails runner 'User.new.delay.raise_the_roof'`
- Run the job queue using `bundle exec rake jobs:workoff`

## Mailman

- Run Mailman with the `run_mailman` script

## Que

- Queue a job with `bin/rails runner 'QueJob.enqueue'`
- Run the job queue with `bundle exec que ./config/environment.rb`

## Rake

- Run a failing Rake task with `bin/rails rake_task:raise`

## Resque

- Queue a job with `bin/rails runner 'Resque.enqueue(ResqueWorker)'`
- Run the job queue with `QUEUE=* bundle exec rake resque:work`

## Shoryuken

_Shoryuken requires a local mock SQS server. See [the instructions](https://github.com/phstc/shoryuken/wiki/Using-a-local-mock-SQS-server) for help setting this up_

In order to use Shoryuken, you need to create a queue. This requires the following environment variables to be set:

- `SHORYUKEN_SQS_ENDPOINT=http://localhost:4576`
- `AWS_REGION=us-west-1`
- `AWS_ACCESS_KEY_ID=foo`
- `AWS_SECRET_ACCESS_KEY=bar`

You can create the "hello" queue with `bundle exec shoryuken sqs create hello`

This setup only needs to be done once each time Moto is started. Now you can use Shoryuken:

- Queue a message with `bin/rails runner 'ShoryukenWorker.perform_async("world")'`
- Run the job queue with `bundle exec shoryuken --rails -q hello`

## Sidekiq

- Queue a job with `bin/rails runner 'SidekiqWorker.perform_async'`
- Run the job queue with `bundle exec sidekiq` (add `-d` to run as a daemon)
