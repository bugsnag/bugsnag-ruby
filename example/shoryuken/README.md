# Using Bugsnag with Shoryuken

This example shows how to use Bugsnag in conjunction with Shoryuken to report any exceptions that occur in your applications.

First, install dependencies
```shell
bundle install
```

## Configuring Bugsnag with Shoryuken

Bugsnag can be configured in one of two ways in your Shoryuken app:

1. require `bugsnag` in your application and call `Bugsnag.configure` with a block, setting the appropriate configuration options:
```ruby
Bugsnag.configure do |config|
    config.api_key = "YOUR_API_KEY"
end
```

2. require `bugsnag` in your application and input configuration options through environment variables, such as setting `BUGSNAG_API_KEY` to `YOUR_API_KEY`.

All configuration options can be found in the [Bugsnag documentation](https://docs.bugsnag.com/platforms/ruby/other/configuration-options/)

## Running the example

Set up your AWS credentials as required in the [Configure the AWS Client](https://github.com/phstc/shoryuken/wiki/Configure-the-AWS-Client) section of the Shoryuken getting started docs.

Start the Shoryuken processor with:
```shell
bundle exec shoryuken -r ./shoryuken.rb
```

In a seperate terminal instance open the console session with:
```shell
bundle exec irb -r ./shoryuken.rb
```

Where you can queue a message with the command:
```ruby
BugsnagTest.perform_async "Hello world"
```