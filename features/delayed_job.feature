Feature: Bugsnag detects errors in Delayed job workers

Scenario: An unhandled RuntimeError sends a report with arguments
  Given I run the service "delayed_job" with the command "bundle exec rake delayed_job_tests:fail_with_args"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "context" equals "TestModel.fail_with_args"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "DelayedJob"
  And the event "app.type" equals "delayed_job"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.job.class" equals "Delayed::Backend::ActiveRecord::Job"
  And the event "metaData.job.id" is not null
  And the event "metaData.job.attempt" equals 1
  And the event "metaData.job.max_attempts" equals 1
  And the event "metaData.job.payload.display_name" equals "TestModel.fail_with_args"
  And the event "metaData.job.payload.method_name" equals "fail_with_args"
  And the event "metaData.job.payload.args.0" equals "Test"
  And the event "device.runtimeVersions.delayed_job" matches "\d+\.\d+\.\d+"

Scenario: A handled exception sends a report
  Given I run the service "delayed_job" with the command "bundle exec rake delayed_job_tests:notify_with_args"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is false
  And the event "severity" equals "warning"
  And the event "context" equals "TestModel.notify_with_args"
  And the event "severityReason.type" equals "handledException"
  And the event "app.type" equals "delayed_job"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.job.class" equals "Delayed::Backend::ActiveRecord::Job"
  And the event "metaData.job.id" is not null
  And the event "metaData.job.attempt" equals 1
  And the event "metaData.job.max_attempts" equals 1
  And the event "metaData.job.payload.display_name" equals "TestModel.notify_with_args"
  And the event "metaData.job.payload.method_name" equals "notify_with_args"
  And the event "metaData.job.payload.args.0" equals "Test"
  And the event "device.runtimeVersions.delayed_job" matches "\d+\.\d+\.\d+"

Scenario: The report context uses the class name if no display name is available
  Given I run the service "delayed_job" with the command "bundle exec rake delayed_job_tests:report_context"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "context" equals "TestReportContextJob"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "DelayedJob"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.job.class" equals "Delayed::Backend::ActiveRecord::Job"
  And the event "metaData.job.id" is not null
  And the event "metaData.job.attempt" equals 1
  And the event "metaData.job.max_attempts" equals 1
  And the event "metaData.job.payload.display_name" is null
  And the event "metaData.job.payload.method_name" is null
  And the event "device.runtimeVersions.delayed_job" matches "\d+\.\d+\.\d+"
