Feature: Mongo automatic breadcrumbs

@rails4 @rails5 @rails6
Scenario: Successful breadcrumbs
  Given I start the rails service
  When I navigate to the route "/mongo/success_crash" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event contains a breadcrumb matching the JSON fixture in "features/fixtures/expected_breadcrumbs/mongo_success.json"

@rails4 @rails5 @rails6
Scenario: Breadcrumb with filter parameters
  Given I start the rails service
  When I navigate to the route "/mongo/get_crash" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event contains a breadcrumb matching the JSON fixture in "features/fixtures/expected_breadcrumbs/mongo_filtered_request.json"
  And the event contains a breadcrumb matching the JSON fixture in "features/fixtures/expected_breadcrumbs/mongo_filtered_result.json"

@rails4 @rails5 @rails6
Scenario: Failure breadcrumbs
  Given I start the rails service
  When I navigate to the route "/mongo/failure_crash" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event contains a breadcrumb matching the JSON fixture in "features/fixtures/expected_breadcrumbs/mongo_failed.json"
