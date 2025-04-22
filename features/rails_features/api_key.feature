Feature: API key

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Setting api_key in environment variable works
  Given I start the rails service
  When I navigate to the route "/api_key/environment" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
 Scenario Outline: Changing api_key after initializer works
  Given I start the rails service
  When I navigate to the route "/api_key/changing?api_key=c35a2a72bd230ac0aa0f52715bbdc6ac" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier with the apiKey "c35a2a72bd230ac0aa0f52715bbdc6ac"
