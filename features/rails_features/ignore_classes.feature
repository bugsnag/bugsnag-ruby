Feature: Ignore classes

@rails3 @rails4 @rails5 @rails6 @rails7
Scenario: Ignore_classes can be set to a different value in initializer
  Given I set environment variable "BUGSNAG_IGNORE_CLASS" to "IgnoredError"
  And I start the rails service
  When I navigate to the route "/ignore_classes/initializer" on the rails app
  Then I should receive no requests

@rails3 @rails4 @rails5 @rails6 @rails7
Scenario: Ignore_classes can be set to a different value after initializer
  Given I start the rails service
  When I navigate to the route "/ignore_classes/after?ignore=IgnoredError" on the rails app
  Then I should receive no requests
