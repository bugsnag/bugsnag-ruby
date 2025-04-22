Feature: Metadata filters

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Meta_data_filters should include Rails.configuration.filter_parameters
  Given I start the rails service
  When I navigate to the route "/metadata_filters/filter?filtered_parameter=foo&other_parameter=bar" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is false
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled string"
  And the event "app.type" equals "rails"
  And the event "metaData.request.url" ends with "/metadata_filters/filter?filtered_parameter=[FILTERED]&other_parameter=bar"
  And the event "metaData.my_specific_filter" equals "[FILTERED]"
  And the event "metaData.request.params.filtered_parameter" equals "[FILTERED]"
  And the event "metaData.request.params.other_parameter" equals "bar"
