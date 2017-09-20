# Upgrade Guide

## 5.x to 6.x

_Our Ruby library has gone through some major improvements and there are a few
changes required to use the new integrations_

#### Capistrano and deploys

Support for notifying Bugsnag of deployments has been separated into a separate
gem named `bugsnag-capistrano`. See the [integration
guide](https://docs.bugsnag.com/platforms/ruby/capistrano) for more information.


#### Configuration

* `Configuration.use_ssl` has been removed. Include the preferred protocol in `Configuration.endpoint` instead.
  ```diff
    Bugsnag.configure do |config|
  -   config.use_ssl = true
  -   config.endpoint = 'myserver.example.com'
  +   config.endpoint = 'https://myserver.example.com'
    end
  ```
* `Configuration.ignore_classes` now no longer accepts strings. Use classes directly instead.
* `Configuration.delay_with_resque` has been removed
* `Configuration.vendor_paths` has been removed
* `Configuration.params_filters` has been renamed to `Configuration.meta_data_filters` to be clearer

#### Notifying

* `notify` now only supports block syntax. Replace usage of the overrides hash with a block

  ```diff
  - Bugsnag.notify(e, {severity: 'info'})
  + Bugsnag.notify(e) do |report|
  +   report.severity = 'info'
  + end
  ```

* `Bugsnag.notify_or_ignore` and `Bugsnag.auto_notify` have been removed removed. Call `notify` directly instead.
* `after_notify_callbacks` has been removed
* `Bugsnag::Notification` has been renamed to `Bugsnag::Report`

#### Logging

* `config.debug` has been removed. Use the logger directly