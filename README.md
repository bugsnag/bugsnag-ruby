# Bugsnag exception reporter for Ruby
[![build status](https://travis-ci.org/bugsnag/bugsnag-ruby.svg?branch=master)](https://travis-ci.org/bugsnag/bugsnag-ruby)


The Bugsnag exception reporter for Ruby gives you instant notification of exceptions thrown from your **[Rails](https://bugsnag.com/platforms/rails)**, **Sinatra**, **Rack** or **plain Ruby** app. Any uncaught exceptions will trigger a notification to be sent to your Bugsnag project.

## Features

* Automatically report unhandled exceptions and crashes
* Report handled exceptions 
* Attach user information to determine how many people are affected by a crash
* Send customized diagnostic data

## Getting started

1. [Create a Bugsnag account](https://bugsnag.com)
2. Complete the instructions in the integration guide for your framework:
    * [Que](http://docs.bugsnag.com/platforms/ruby/que)
    * [Rack](http://docs.bugsnag.com/platforms/ruby/rack)
    * [Rails](http://docs.bugsnag.com/platforms/ruby/rails)
    * [Rake](http://docs.bugsnag.com/platforms/ruby/rake)
    * [Sidekiq](http://docs.bugsnag.com/platforms/ruby/sidekiq)
    * [Other Ruby apps](http://docs.bugsnag.com/platforms/ruby/other)
    * For [EventMachine](http://rubyeventmachine.com) integration, see [`bugsnag-em`](https://github.com/bugsnag/bugsnag-em)
3. Relax!

## Support

* Read the configuration reference:
    * [Que](http://docs.bugsnag.com/platforms/ruby/que/configuration-options)
    * [Rack](http://docs.bugsnag.com/platforms/ruby/rack/configuration-options)
    * [Rails](http://docs.bugsnag.com/platforms/ruby/rails/configuration-options)
    * [Rake](http://docs.bugsnag.com/platforms/ruby/rake/configuration-options)
    * [Sidekiq](http://docs.bugsnag.com/platforms/ruby/sidekiq/configuration-options)
    * [Other Ruby apps](http://docs.bugsnag.com/platforms/ruby/other/configuration-options)
* Check out some [example apps integrated with Bugsnag](https://github.com/bugsnag/bugsnag-example-apps/tree/master/apps/ruby) using Rails, Sinatra, Padrino, and more.
* [Search open and closed issues](https://github.com/bugsnag/bugsnag-ruby/issues?utf8=✓&q=is%3Aissue) for similar problems
* [Report a bug or request a feature](https://github.com/bugsnag/bugsnag-ruby/issues/new)

## Contributing

All contributors are welcome! For information on how to build, test and release `bugsnag-ruby`, see our [contributing guide](https://github.com/bugsnag/bugsnag-ruby/blob/master/CONTRIBUTING.md). Feel free to comment on [existing issues](https://github.com/bugsnag/bugsnag-ruby/issues) for clarification or starting points.

## License

The Bugsnag ruby notifier is free software released under the MIT License. See [LICENSE.txt](LICENSE.txt) for details.
