Feature: API key

# Scenario Outline: Setting api_key in environment variable works
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6a1"
  And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/unhandled" on port "<port>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the Ruby notifier
  And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6a1"
  And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6a1"
  And the payload field "events" is an array with 1 element

# Scenario Outline: Changing api_key after initializer works
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/set_config_option?name=api_key&value=a35a2a72bd230ac0aa0f52715bbdc6a2" on port "<port>"
  And I navigate to the route "/unhandled" on port "<port>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the Ruby notifier
  And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6a2"
  And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6a2"
  And the payload field "events" is an array with 1 element