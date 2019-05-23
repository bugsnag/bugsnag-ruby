# Upgrade Guide

## 5.x to 6.x

_Our Ruby library has gone through some major improvements and there are a few
changes required to use the new integrations_

#### Capistrano and deploys

Support for notifying Bugsnag of deployments has been separated into a separate
gem named `bugsnag-capistrano`. See the [integration
guide](https://docs.bugsnag.com/api/deploy-tracking/capistrano/) for more information.


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
* `Configuration.proxy_host` will now default to `ENV['http_proxy']` if set. It can still be manually set.

#### Notifying

* `notify` now only supports block syntax. Replace usage of the overrides hash with a block

  ```diff
  - Bugsnag.notify(e, {severity: 'info'})
  + Bugsnag.notify(e) do |report|
  +   report.severity = 'info'
  + end
  ```

* `Bugsnag.notify_or_ignore` and `Bugsnag.auto_notify` have been removed. Call `notify` directly instead.
* `after_notify_callbacks` has been removed
* `Bugsnag::Notification` has been renamed to `Bugsnag::Report`

#### Logging

* `config.debug` boolean has been removed. Set the logger level directly

  ```diff
  + require 'logger'

    Bugsnag.configure do |config|
      # .. set API key and other properties
  -   config.debug = true
  +   config.logger.level = Logger::DEBUG
    end
  ```

* Log accessor functions on the `Bugsnag` object no longer exist. Logging must now be accessed through the configuration object:

  ```diff
  - Bugsnag.log "Log message"
  - Bugsnag.warn "Warn message"
  - Bugsnag.debug "Debug message"
  + Bugsnag.configuration.logger.info "Info message"
  + Bugsnag.configuration.logger.warn "Warn message"
  + Bugsnag.configuration.logger.debug "Debug message"
  ```

#### Middleware

* If you previously accessed objects directly through `notification.exceptions`, this has now moved to `notification.raw_exceptions`

  ```diff
  class ExampleMiddleware
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(report)
  -   exception = report.exceptions.first
  +   exception = report.raw_exceptions.first
      status = report.response.status
      
      # do stuff
      
      @bugsnag.call(report)
    end
  end
  ```
