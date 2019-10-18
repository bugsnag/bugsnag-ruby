Feature: Rails automatic breadcrumbs

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

@rails3 @rails4 @rails5 @rails6
Scenario Outline: Request breadcrumb
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/breadcrumbs/handled" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event has a "request" breadcrumb named "Controller started processing"
  And the event "breadcrumbs.0.timestamp" is a timestamp
  And the event "breadcrumbs.0.metaData.controller" equals "BreadcrumbsController"
  And the event "breadcrumbs.0.metaData.action" equals "handled"
  And the event "breadcrumbs.0.metaData.method" equals "GET"
  And the event "breadcrumbs.0.metaData.path" equals "/breadcrumbs/handled"
  And the event "breadcrumbs.0.metaData.event_name" equals "start_processing.action_controller"
  And the event "breadcrumbs.0.metaData.event_id" is not null

  Examples:
    | ruby_version | rails_version |
    | 2.0          | 3             |
    | 2.1          | 3             |
    | 2.2          | 3             |
    | 2.2          | 4             |
    | 2.2          | 5             |
    | 2.3          | 3             |
    | 2.3          | 4             |
    | 2.3          | 5             |
    | 2.4          | 3             |
    | 2.4          | 5             |
    | 2.5          | 3             |
    | 2.5          | 5             |
    | 2.5          | 6             |
    | 2.6          | 5             |
    | 2.6          | 6             |

@rails3 @rails4 @rails5 @rails6
Scenario Outline: SQL Breadcrumb without bindings
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I set environment variable "SQL_ONLY_BREADCRUMBS" to "true"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/breadcrumbs/sql_breadcrumb" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event has a "process" breadcrumb named "ActiveRecord SQL query"
  And the event "breadcrumbs.0.timestamp" is a timestamp
  And the event "breadcrumbs.0.metaData.name" equals "User Load"
  And the event "breadcrumbs.0.metaData.connection_id" is not null
  And the event "breadcrumbs.0.metaData.event_name" equals "sql.active_record"
  And the event "breadcrumbs.0.metaData.event_id" is not null

  Examples:
    | ruby_version | rails_version |
    | 2.0          | 3             |
    | 2.1          | 3             |
    | 2.2          | 3             |
    | 2.2          | 4             |
    | 2.3          | 3             |
    | 2.3          | 4             |
    | 2.4          | 3             |
    | 2.5          | 3             |
    | 2.5          | 6             |
    | 2.6          | 5             |
    | 2.6          | 6             |

@rails5 @rails6
Scenario Outline: SQL Breadcrumb with bindings
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I set environment variable "SQL_ONLY_BREADCRUMBS" to "true"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/breadcrumbs/sql_breadcrumb" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event has a "process" breadcrumb named "ActiveRecord SQL query"
  And the event "breadcrumbs.0.timestamp" is a timestamp
  And the event "breadcrumbs.0.metaData.name" equals "User Load"
  And the event "breadcrumbs.0.metaData.connection_id" is not null
  And the event "breadcrumbs.0.metaData.event_name" equals "sql.active_record"
  And the event "breadcrumbs.0.metaData.event_id" is not null
  And the event "breadcrumbs.0.metaData.binds" equals "{"email":"?","LIMIT":"?"}"

  Examples:
    | ruby_version | rails_version |
    | 2.2          | 5             |
    | 2.3          | 5             |
    | 2.4          | 5             |
    | 2.5          | 5             |
    | 2.5          | 6             |
    | 2.6          | 5             |
    | 2.6          | 6             |

@rails4 @rails5 @rails6
Scenario Outline: Active job breadcrumb
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/breadcrumbs/active_job" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event has a "process" breadcrumb named "Start perform ActiveJob"
  And the event "breadcrumbs.0.timestamp" is a timestamp
  And the event "breadcrumbs.0.metaData.event_name" equals "perform_start.active_job"
  And the event "breadcrumbs.0.metaData.event_id" is not null

  Examples:
    | ruby_version | rails_version |
    | 2.2          | 4             |
    | 2.2          | 5             |
    | 2.3          | 4             |
    | 2.3          | 5             |
    | 2.4          | 5             |
    | 2.5          | 5             |
    | 2.5          | 6             |
    | 2.6          | 5             |
    | 2.6          | 6             |

@rails4 @rails5 @rails6
Scenario Outline: Cache read
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/breadcrumbs/cache_read" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event has a "process" breadcrumb named "Read cache"

  Examples:
    | ruby_version | rails_version |
    | 2.2          | 4             |
    | 2.2          | 5             |
    | 2.3          | 4             |
    | 2.3          | 5             |
    | 2.4          | 5             |
    | 2.5          | 5             |
    | 2.5          | 6             |
    | 2.6          | 5             |
    | 2.6          | 6             |
