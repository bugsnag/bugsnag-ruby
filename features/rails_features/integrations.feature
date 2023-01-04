Feature: App type is set correctly for integrations in a Rails app

@rails_integrations
Scenario: Delayed job
  Given I start the rails service with the database
  And I run the "jobs:work" rake task in the rails app in the background
  When I run "User.new.delay.raise_the_roof" with the rails runner
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "context" equals "User#raise_the_roof"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "DelayedJob"
  And the event "app.type" equals "delayed_job"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.job.class" equals "Delayed::Backend::ActiveRecord::Job"
  And the event "metaData.job.id" is not null
  And the event "metaData.job.attempt" equals 1
  And the event "metaData.job.max_attempts" equals 25
  And the event "metaData.job.payload.display_name" equals "User#raise_the_roof"
  And the event "metaData.job.payload.method_name" equals "raise_the_roof"

@rails_integrations
Scenario: Mailman
  Given I start the rails service
  When I run "./run_mailman" in the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "context" is null
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Mailman"
  And the event "app.type" equals "mailman"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.mailman.message" starts with "Date: Mon, 04 Feb 2019 17:54:01 +0000"

@rails_integrations
Scenario: Que
  Given I start the rails service with the database
  And I run "bundle exec que ./config/environment.rb" in the rails app in the background
  When I run "QueJob.enqueue" with the rails runner
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Que"
  And the event "app.type" equals "que"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.job.job_id" equals 1
  And the event "metaData.job.job_class" equals "QueJob"

@rails_integrations
Scenario: Rake
  Given I start the rails service
  When I run the "rake_task:raise" rake task in the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Rake"
  And the event "app.type" equals "rake"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.rake_task.name" equals "rake_task:raise"
  And the event "metaData.rake_task.description" is null
  And the event "metaData.rake_task.arguments" is null

@rails_integrations
Scenario: Resque (no on_exit hooks)
  Given I start the rails service
  And I run the "resque:work" rake task in the rails app in the background
  When I run the "fixture:queue_resque_job" rake task in the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "context" equals "ResqueWorker@crash"
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Resque"
  And the event "app.type" equals "resque"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.config.delivery_method" equals "synchronous"
  And the event "metaData.context" equals "ResqueWorker@crash"
  And the event "metaData.payload.class" equals "ResqueWorker"
  And the event "metaData.payload.args.0" equals 123
  And the event "metaData.payload.args.1" equals "abc"
  And the event "metaData.payload.args.2.0" equals 7
  And the event "metaData.payload.args.2.1" equals 8
  And the event "metaData.payload.args.2.2" equals 9
  And the event "metaData.payload.args.3.x" is true
  And the event "metaData.payload.args.3.y" is false
  And the event "metaData.rake_task.name" equals "resque:work"
  And the event "metaData.rake_task.description" equals "Start a Resque worker"
  And the event "metaData.rake_task.arguments" is null

@rails_integrations
Scenario: Resque (with on_exit hooks)
  Given I set environment variable "RUN_AT_EXIT_HOOKS" to "1"
  And I start the rails service
  And I run the "resque:work" rake task in the rails app in the background
  When I run the "fixture:queue_resque_job" rake task in the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "context" equals "ResqueWorker@crash"
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Resque"
  And the event "app.type" equals "resque"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.config.delivery_method" equals "thread_queue"
  And the event "metaData.context" equals "ResqueWorker@crash"
  And the event "metaData.payload.class" equals "ResqueWorker"
  And the event "metaData.payload.args.0" equals 123
  And the event "metaData.payload.args.1" equals "abc"
  And the event "metaData.payload.args.2.0" equals 7
  And the event "metaData.payload.args.2.1" equals 8
  And the event "metaData.payload.args.2.2" equals 9
  And the event "metaData.payload.args.3.x" is true
  And the event "metaData.payload.args.3.y" is false
  And the event "metaData.rake_task.name" equals "resque:work"
  And the event "metaData.rake_task.description" equals "Start a Resque worker"
  And the event "metaData.rake_task.arguments" is null

@rails_integrations
Scenario: Sidekiq
  Given I start the rails service
  And I run "bundle exec sidekiq" in the rails app in the background
  When I run "SidekiqWorker.perform_async" with the rails runner
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "context" equals "SidekiqWorker@default"
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Sidekiq"
  And the event "app.type" equals "sidekiq"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.sidekiq.msg.queue" equals "default"
  And the event "metaData.sidekiq.msg.class" equals "SidekiqWorker"
  And the event "metaData.sidekiq.queue" equals "default"

@rails_integrations
Scenario: Using Sidekiq as the Active Job queue adapter for a job that raises
  Given I set environment variable "ACTIVE_JOB_QUEUE_ADAPTER" to "sidekiq"
  And I start the rails service
  And I run "bundle exec sidekiq" in the rails app in the background
  When I run the "fixture:queue_unhandled_job" rake task in the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "context" equals "UnhandledJob@default"
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Sidekiq"
  And the event "app.type" equals "sidekiq"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.active_job" is null
  And the event "metaData.sidekiq.msg.queue" equals "default"
  And the event "metaData.sidekiq.msg.class" equals "ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper"
  And the event "metaData.sidekiq.msg.wrapped" equals "UnhandledJob"
  And the event "metaData.sidekiq.msg.args.0.arguments.0" equals 1
  And the event "metaData.sidekiq.msg.args.0.arguments.1.yes" is true
  And the event "metaData.sidekiq.queue" equals "default"

@rails_integrations
Scenario: Using Resque as the Active Job queue adapter for a job that raises
  Given I set environment variable "ACTIVE_JOB_QUEUE_ADAPTER" to "resque"
  And I start the rails service
  And I run the "resque:work" rake task in the rails app in the background
  When I run the "fixture:queue_unhandled_job" rake task in the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "context" equals "UnhandledJob@default"
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Resque"
  And the event "app.type" equals "resque"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.active_job" is null
  And the event "metaData.payload.class" equals "ActiveJob::QueueAdapters::ResqueAdapter::JobWrapper"
  And the event "metaData.payload.wrapped" equals "UnhandledJob"
  And the event "metaData.payload.args.0.arguments.0" equals 1
  And the event "metaData.payload.args.0.arguments.1.yes" is true
  And the event "metaData.payload.args.0.queue_name" equals "default"

@rails_integrations
Scenario: Using Que as the Active Job queue adapter for a job that raises
  Given I set environment variable "ACTIVE_JOB_QUEUE_ADAPTER" to "que"
  And I start the rails service with the database
  And I run "bundle exec que -q default ./config/environment.rb" in the rails app in the background
  When I run the "fixture:queue_unhandled_job" rake task in the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "context" is null
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Que"
  And the event "app.type" equals "que"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.active_job" is null
  And the event "metaData.job.wrapper_job_class" equals "ActiveJob::QueueAdapters::QueAdapter::JobWrapper"
  And the event "metaData.job.job_class" equals "UnhandledJob"
  And the event "metaData.job.args.0" equals 1
  And the event "metaData.job.args.1.yes" is true
  And the event "metaData.job.queue" equals "default"

@rails_integrations
Scenario: Using Delayed Job as the Active Job queue adapter for a job that raises
  Given I set environment variable "ACTIVE_JOB_QUEUE_ADAPTER" to "delayed_job"
  And I start the rails service with the database
  And I run the "jobs:work" rake task in the rails app in the background
  When I run the "fixture:queue_unhandled_job" rake task in the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "context" equals "UnhandledJob@default"
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "DelayedJob"
  And the event "app.type" equals "delayed_job"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.active_job" is null
  And the event "metaData.job.payload.class" equals "ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper"
  And the event "metaData.job.payload.job_class" equals "UnhandledJob"
  And the event "metaData.job.payload.arguments.0" equals 1
  And the event "metaData.job.payload.arguments.1.yes" is true
  And the event "metaData.job.queue" equals "default"

@rails_integrations
Scenario: Using Sidekiq as the Active Job queue adapter for a job that works
  Given I set environment variable "ACTIVE_JOB_QUEUE_ADAPTER" to "sidekiq"
  And I start the rails service
  And I run "bundle exec sidekiq" in the rails app in the background
  When I run the "fixture:queue_working_job" rake task in the rails app
  Then I should receive no requests

@rails_integrations
Scenario: Using Resque as the Active Job queue adapter for a job that works
  Given I set environment variable "ACTIVE_JOB_QUEUE_ADAPTER" to "resque"
  And I start the rails service
  And I run "bundle exec rake resque:work" in the rails app in the background
  When I run the "fixture:queue_working_job" rake task in the rails app
  Then I should receive no requests

@rails_integrations
Scenario: Using Que as the Active Job queue adapter for a job that works
  Given I set environment variable "ACTIVE_JOB_QUEUE_ADAPTER" to "que"
  And I start the rails service with the database
  And I run "bundle exec que -q default ./config/environment.rb" in the rails app in the background
  When I run the "fixture:queue_working_job" rake task in the rails app
  Then I should receive no requests

@rails_integrations
Scenario: Using Delayed Job as the Active Job queue adapter for a job that works
  Given I set environment variable "ACTIVE_JOB_QUEUE_ADAPTER" to "delayed_job"
  And I start the rails service with the database
  And I run the "jobs:work" rake task in the rails app in the background
  When I run the "fixture:queue_working_job" rake task in the rails app
  Then I should receive no requests
