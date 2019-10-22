Feature: Mongo automatic breadcrumbs

@rails4 @rails5 @rails6 @wip
Scenario: Successful breadcrumbs
  Given I start the rails service
  When I navigate to the route "/mongo/success_crash" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event has a "process" breadcrumb named "Mongo query succeeded"
  And the event "breadcrumbs.1.timestamp" is a timestamp
  And the event "breadcrumbs.1.metaData.event_name" equals "mongo.succeeded"
  And the event "breadcrumbs.1.metaData.command_name" equals "insert"
  And the event "breadcrumbs.1.metaData.operation_id" is not null
  And the event "breadcrumbs.1.metaData.request_id" is not null
  And the event "breadcrumbs.1.metaData.duration" is not null
  And the event "breadcrumbs.1.metaData.collection" equals "mongo_models"

@rails4 @rails5 @rails6 @wip
Scenario: Breadcrumb with filter parameters
  Given I start the rails service
  When I navigate to the route "/mongo/get_crash" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
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
  And the event "breadcrumbs.2.metaData.operation_id" is not null
  And the event "breadcrumbs.2.metaData.request_id" is not null
  And the event "breadcrumbs.2.metaData.duration" is not null
  And the event "breadcrumbs.2.metaData.collection" equals "mongo_models"
  And the event "breadcrumbs.2.metaData.filter" equals "{"$or":[{"string_field":"?"},{"numeric_field":"?"}]}"

@rails4 @rails5 @rails6 @wip
Scenario: Failure breadcrumbs
  Given I start the rails service
  When I navigate to the route "/mongo/failure_crash" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event has a "process" breadcrumb named "Mongo query failed"
  And the event "breadcrumbs.1.timestamp" is a timestamp
  And the event "breadcrumbs.1.metaData.event_name" equals "mongo.failed"
  And the event "breadcrumbs.1.metaData.command_name" equals "bogus"
  And the event "breadcrumbs.1.metaData.database_name" equals "rails<rails_version>_development"
  And the event "breadcrumbs.1.metaData.operation_id" is not null
  And the event "breadcrumbs.1.metaData.request_id" is not null
  And the event "breadcrumbs.1.metaData.duration" is not null
  And the event "breadcrumbs.1.metaData.collection" equals 1
