Feature: Rails 4 support

Background:
  Given I configure the bugsnag endpoint
  And I start the compose stack "features/fixtures/rails4/docker-compose.yml"

# Unhandled Errors
Scenario Outline: Unandled RuntimeError
  Given I wait for the app to respond on port "<port>"
  When I navigate to the route "/unhandled" on port "<port>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the Ruby notifier
  And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"

  Examples:
    | port |
    | 3000 |
    | 3001 |
    | 3002 |
    | 3003 |
    | 3004 |
    | 3005 |
Scenario Outline: Request information from Rails is included with unhandled errors

# Handled Errors
Scenario Outline: Unthrown handled RuntimeError
  Given I wait for the app to respond on port "<port>"
  When I navigate to the route "/handled" on port "<port>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the Ruby notifier
  And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"

  Examples:
    | port |
    | 3000 |
    | 3001 |
    | 3002 |
    | 3003 |
    | 3004 |
    | 3005 |
Scenario Outline: Thrown handled RuntimeError
Scenario Outline: Manual string notify
  Given I wait for the app to respond on port "<port>"
  When I navigate to the route "/string_notify" on port "<port>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the Ruby notifier
  And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"

  Examples:
    | port |
    | 3000 |
    | 3001 |
    | 3002 |
    | 3003 |
    | 3004 |
    | 3005 |
Scenario Outline: Request information from Rails is included with handled errors

# Exception properties
Scenario Outline: Setting skip_bugsnag on exception wont auto_notify
Scenario Outline: Setting bugsnag_meta_data on exception is attached to a handled error
Scenario Outline: Setting bugsnag_meta_data on exception is attached to an unhandled error
Scenario Outline: Setting bugsnag_user_id on exception is attached to a handled error
Scenario Outline: Setting bugsnag_user_id on exception is attached to an unhandled error
Scenario Outline: Setting bugsnag_context on exception is attached to a handled error
Scenario Outline: Setting bugsnag_context on exception is attached to an unhandled error
Scenario Outline: Setting bugsnag_grouping_hash on exception is attached to a handled error
Scenario Outline: Setting bugsnag_grouping_hash on exception is attached to an unhandled error

# Before notify callbacks
Scenario Outline: Rails before_notify controller method works on handled errors
Scenario Outline: Rails before_notify controller method works on unhandled errors
Scenario Outline: Inline block on handled errors is called
Scenario Outline: Global callbacks called for handled errors
Scenario Outline: Global callbacks called for unhandled errors

# User information
Scenario Outline: Devise user information is sent on handled errors
Scenario Outline: Devise user information is sent on unhandled errors
Scenario Outline: Warden user information is sent on handled errors
Scenario Outline: Warden user information is sent on unhandled errors
Scenario Outline: Clearance user information is sent on handled errors
Scenario Outline: Clearance user information is sent on unhandled errors

# Session tracking
Scenario Outline: Manual session tracking sends session information
Scenario Outline: Session tracking information is included in unhandled errors for manual sessions
Scenario Outline: Session tracking information is included in handled errors for manual sessions
Scenario Outline: Session tracking information is included in unhandled errors for automatic sessions
Scenario Outline: Session tracking information is included in handled errors for automatic sessions

# Config options
## api_key
Scenario Outline: Setting api_key in environment variable works
Scenario Outline: Setting api_key in initializer works
Scenario Outline: Changing api_key after initializer works

## app_type
Scenario Outline: App_type is automatically set to rails for handled errors
Scenario Outline: App_type is automatically set to rails for unhandled errors
Scenario Outline: Setting app_type in initializer works
Scenario Outline: Changing app_type after initializer works

## app_version
Scenario Outline: App_version is nil by default
Scenario Outline: Setting app_version in initializer works
Scenario Outline: Setting app_version after initializer works

## auto_notify
Scenario Outline: Auto_notify is true by default
Scenario Outline: Auto_notify can be set to false in the initializer
Scenario Outline: Auto_notify can be set to false after the initializer

## auto_capture_sessions
Scenario Outline: Auto_capture_sessions is false by default
Scenario Outline: Auto_capture_sessions can be set to true in the initializer
Scenario Outline: Auto_capture_sessions can be set to true after the initializer

## endpoint
Scenario Outline: Endpoint is notify.bugsnag.com by default
Scenario Outline: Endpoint can be set to different value in the initializer

## ignore_classes
Scenario Outline: Ignore_classes is SystemExit and Interrupt by default
Scenario Outline: Ignore_classes can be set to a different value in initializer
Scenario Outline: Ignore_classes can be set to a different value after initializer
Scenario Outline: Ignore_classes can contain a class reference
Scenario Outline: Ignore_classes can contain a lambda

## logger
Scenario Outline: Logger is set to Rails.logger by default
Scenario Outline: Logger can be updated in initializer
Scenario Outline: Logger can be updated after the initializer

## meta_data_filters
Scenario Outline: Meta_data_filters should have sensible defaults from bugsnag
Scenario Outline: Meta_data_filters should include Rails.configuration.filter_parameters
Scenario Outline: Meta_data_filters should cope with strings
Scenario Outline: Meta_data_filters should cope with regular expressions

## notify_release_stages
Scenario Outline: Notify_release_stages should be nil by default
Scenario Outline: Notify_release_stages should block sending in that release stage
Scenario Outline: Notify_release_stages should allow sending in other release stages
Scenario Outline: Notify_release_stages should send in any release stage if its nil

## project_root
Scenario Outline: Project_root should default to Rails.root
Scenario Outline: Project_root can be set in an initializer
Scenario Outline: Project_root can be set after an initializer

## proxy
Scenario Outline: Proxy_host should work
Scenario Outline: Http_proxy environment variable should work
Scenario Outline: Proxy_password should work
Scenario Outline: Proxy_port should work
Scenario Outline: Proxy_user should work

## release_stage
Scenario Outline: Release_stage should default to RAILS_ENV
Scenario Outline: Release_stage can be set in an initializer
Scenario Outline: Release_stage can be set after an initializer

## send_environment
Scenario Outline: Send_environment should default to false
Scenario Outline: Send_environment should send environment in handled errors when true
Scenario Outline: Send_environment should send environment in unhandled errors when true

## send_code
Scenario Outline: Send_code should default to true
Scenario Outline: Send_code can be updated in an initializer
Scenario Outline: Send_code can be updated after an initializer

## session_endpoint
Scenario Outline: Session_endpoint is sessions.bugsnag.com by default
Scenario Outline: Session_endpoint can be set to different value in the initializer

## timeout
Scenario Outline: Timeout is 15 seconds by default
Scenario Outline: Timeout can be changed in the initializer
Scenario Outline: Timeout can be changed after the initializer

# Report
## add_tab
Scenario Outline: Can call add_tab on report to add ui tab
Scenario Outline: Can call add_tab on report to merge info in ui tab

## api_key
Scenario Outline: Can set the api_key on a report

## context
Scenario Outline: Can set the context on a report

## exceptions
Scenario Outline: Can read exceptions from a report

## grouping_hash
Scenario Outline: Can set a grouping hash on a report

## ignore!
Scenario Outline: Can ignore a report

## meta_data
Scenario Outline: Can read meta_data from a report
Scenario Outline: Can write to the meta_data in a report

## remove_tab
Scenario Outline: Can remove a tab from a report

## severity
Scenario Outline: Can set severity of a report to error
Scenario Outline: Can set severity of a report to warning
Scenario Outline: Can set severity of a report to info

## user
Scenario Outline: Can set user id in a report
Scenario Outline: Can set user email in a report
Scenario Outline: Can set user name in a report
Scenario Outline: Can set other user information in a report
Scenario Outline: Can unset user in a report
