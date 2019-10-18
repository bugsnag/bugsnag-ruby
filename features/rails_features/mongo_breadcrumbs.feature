Feature: Mongo automatic breadcrumbs

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

@rails4 @rails5 @rails6
Scenario Outline: Successful breadcrumbs
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/mongo/success_crash" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event has a "process" breadcrumb named "Mongo query succeeded"
  And the event "breadcrumbs.1.timestamp" is a timestamp
  And the event "breadcrumbs.1.metaData.event_name" equals "mongo.succeeded"
  And the event "breadcrumbs.1.metaData.command_name" equals "insert"
  And the event "breadcrumbs.1.metaData.database_name" equals "rails<rails_version>_development"
  And the event "breadcrumbs.1.metaData.operation_id" is not null
  And the event "breadcrumbs.1.metaData.request_id" is not null
  And the event "breadcrumbs.1.metaData.duration" is not null
  And the event "breadcrumbs.1.metaData.collection" equals "mongo_models"

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
Scenario Outline: Breadcrumb with filter parameters
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/mongo/get_crash" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event has a "process" breadcrumb named "Mongo query succeeded"
  And the event "breadcrumbs.1.timestamp" is a timestamp
  And the event "breadcrumbs.1.metaData.event_name" equals "mongo.succeeded"
  And the event "breadcrumbs.1.metaData.command_name" equals "find"
  And the event "breadcrumbs.1.metaData.database_name" equals "rails<rails_version>_development"
  And the event "breadcrumbs.1.metaData.operation_id" is not null
  And the event "breadcrumbs.1.metaData.request_id" is not null
  And the event "breadcrumbs.1.metaData.duration" is not null
  And the event "breadcrumbs.1.metaData.collection" equals "mongo_models"
  And the event "breadcrumbs.1.metaData.filter" equals "{"string_field":"?"}"
  And the event "breadcrumbs.2.timestamp" is a timestamp
  And the event "breadcrumbs.2.metaData.event_name" equals "mongo.succeeded"
  And the event "breadcrumbs.2.metaData.command_name" equals "find"
  And the event "breadcrumbs.2.metaData.database_name" equals "rails<rails_version>_development"
  And the event "breadcrumbs.2.metaData.operation_id" is not null
  And the event "breadcrumbs.2.metaData.request_id" is not null
  And the event "breadcrumbs.2.metaData.duration" is not null
  And the event "breadcrumbs.2.metaData.collection" equals "mongo_models"
  And the event "breadcrumbs.2.metaData.filter" equals "{"$or":[{"string_field":"?"},{"numeric_field":"?"}]}"

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
Scenario Outline: Failure breadcrumbs
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/mongo/failure_crash" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event has a "process" breadcrumb named "Mongo query failed"
  And the event "breadcrumbs.1.timestamp" is a timestamp
  And the event "breadcrumbs.1.metaData.event_name" equals "mongo.failed"
  And the event "breadcrumbs.1.metaData.command_name" equals "bogus"
  And the event "breadcrumbs.1.metaData.database_name" equals "rails<rails_version>_development"
  And the event "breadcrumbs.1.metaData.operation_id" is not null
  And the event "breadcrumbs.1.metaData.request_id" is not null
  And the event "breadcrumbs.1.metaData.duration" is not null
  And the event "breadcrumbs.1.metaData.collection" equals 1

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