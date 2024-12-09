Feature: Release stage

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Release_stage should default to RAILS_ENV
  Given I set environment variable "RAILS_ENV" to "rails_env"
  And I start the rails service
  When I navigate to the route "/release_stage/default" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "app.releaseStage" equals "rails_env"

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Release_stage can be set in an initializer
  Given I set environment variable "BUGSNAG_RELEASE_STAGE" to "maze_release_stage_env"
  And I start the rails service
  When I navigate to the route "/release_stage/default" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "app.releaseStage" equals "maze_release_stage_env"

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Release_stage can be set after an initializer
  Given I start the rails service
  When I navigate to the route "/release_stage/after?stage=set_after_env" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "app.releaseStage" equals "set_after_env"
