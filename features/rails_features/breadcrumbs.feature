Feature: Rails automatic breadcrumbs

@rails3 @rails4 @rails5 @rails6
Scenario: Request breadcrumb
  Given I start the rails service
  When I navigate to the route "/breadcrumbs/handled" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event contains a breadcrumb matching the JSON fixture in "features/fixtures/expected_breadcrumbs/request.json"

@rails3 @rails4
Scenario: SQL Breadcrumb without bindings
  Given I set environment variable "SQL_ONLY_BREADCRUMBS" to "true"
  And I start the rails service
  When I navigate to the route "/breadcrumbs/sql_breadcrumb" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event contains a breadcrumb matching the JSON fixture in "features/fixtures/expected_breadcrumbs/sql_without_bindings.json"

@rails5 @rails6
Scenario: SQL Breadcrumb with bindings
  Given I set environment variable "SQL_ONLY_BREADCRUMBS" to "true"
  And I start the rails service
  When I navigate to the route "/breadcrumbs/sql_breadcrumb" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event contains a breadcrumb matching the JSON fixture in "features/fixtures/expected_breadcrumbs/sql_with_bindings.json"

@rails4 @rails5 @rails6
Scenario: Active job breadcrumb
  Given I start the rails service
  When I navigate to the route "/breadcrumbs/active_job" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event contains a breadcrumb matching the JSON fixture in "features/fixtures/expected_breadcrumbs/active_job.json"

@rails4 @rails5 @rails6
Scenario: Cache read
  Given I start the rails service
  When I navigate to the route "/breadcrumbs/cache_read" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event has a "process" breadcrumb named "Read cache"
