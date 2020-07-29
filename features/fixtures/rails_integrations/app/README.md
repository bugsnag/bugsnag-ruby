# README

## DelayedJob

- Queue a job with `bin/rails runner 'User.new.delay.raise_the_roof'`
- Run the job queue using `bundle exec rake jobs:workoff`

## Que

- Queue a job with `bin/rails runner 'QueJob.enqueue'`
- Run the job queue with `bundle exec que ./config/environment.rb`

## Rake

- Run a failing Rake task with `bin/rails rake_task:raise`

## Resque

- Queue a job with `bin/rails runner 'Resque.enqueue(ResqueWorker)'`
- Run the job queue with `QUEUE=* bundle exec rake resque:work`

## Sidekiq

- Queue a job with `bin/rails runner 'SidekiqWorker.perform_async'`
- Run the job queue with `bundle exec sidekiq` (add `-d` to run as a daemon)
