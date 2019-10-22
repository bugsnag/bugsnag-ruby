Feature: Rails automatic breadcrumbs

@rails3 @rails4 @rails5 @rails6 @wip
Scenario: Request breadcrumb
  Given I start the rails service
  When I navigate to the route "/breadcrumbs/handled" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event has a "request" breadcrumb named "Controller started processing"
  And the event "breadcrumbs.0.timestamp" is a timestamp
  And the event "breadcrumbs.0.metaData.controller" equals "BreadcrumbsController"
  And the event "breadcrumbs.0.metaData.action" equals "handled"
  And the event "breadcrumbs.0.metaData.method" equals "GET"
  And the event "breadcrumbs.0.metaData.path" equals "/breadcrumbs/handled"
  And the event "breadcrumbs.0.metaData.event_name" equals "start_processing.action_controller"
  And the event "breadcrumbs.0.metaData.event_id" is not null

@rails3 @rails4 @rails5 @rails6 @wip
Scenario: SQL Breadcrumb without bindings
  Given I set environment variable "SQL_ONLY_BREADCRUMBS" to "true"
  And I start the rails service
  When I navigate to the route "/breadcrumbs/sql_breadcrumb" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event has a "process" breadcrumb named "ActiveRecord SQL query"
  And the event "breadcrumbs.0.timestamp" is a timestamp
  And the event "breadcrumbs.0.metaData.name" equals "User Load"
  And the event "breadcrumbs.0.metaData.connection_id" is not null
  And the event "breadcrumbs.0.metaData.event_name" equals "sql.active_record"
  And the event "breadcrumbs.0.metaData.event_id" is not null

@rails5 @rails6 @wip
Scenario: SQL Breadcrumb with bindings
  Given I set environment variable "SQL_ONLY_BREADCRUMBS" to "true"
  And I start the rails service
  When I navigate to the route "/breadcrumbs/sql_breadcrumb" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event has a "process" breadcrumb named "ActiveRecord SQL query"
  And the event "breadcrumbs.0.timestamp" is a timestamp
  And the event "breadcrumbs.0.metaData.name" equals "User Load"
  And the event "breadcrumbs.0.metaData.connection_id" is not null
  And the event "breadcrumbs.0.metaData.event_name" equals "sql.active_record"
  And the event "breadcrumbs.0.metaData.event_id" is not null
  And the event "breadcrumbs.0.metaData.binds" equals "{\"email\":\"?\",\"LIMIT\":\"?\"}"

@rails4 @rails5 @rails6 @wip
Scenario: Active job breadcrumb
  Given I start the rails service
  When I navigate to the route "/breadcrumbs/active_job" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event has a "process" breadcrumb named "Start perform ActiveJob"
  And the event "breadcrumbs.0.timestamp" is a timestamp
  And the event "breadcrumbs.0.metaData.event_name" equals "perform_start.active_job"
  And the event "breadcrumbs.0.metaData.event_id" is not null

@rails4 @rails5 @rails6 @wip
Scenario: Cache read
  Given I start the rails service
  When I navigate to the route "/breadcrumbs/cache_read" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event has a "process" breadcrumb named "Read cache"
