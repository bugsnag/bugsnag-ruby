# encoding: utf-8
require 'spec_helper'
require 'support/shared_examples_for_metadata'

describe Bugsnag::Configuration do
  describe "delivery_method" do
    it "should have the default delivery method" do
      expect(subject.delivery_method).to eq(:thread_queue)
    end

    it "should have the defined delivery_method" do
      subject.delivery_method = :test
      expect(subject.delivery_method).to eq(:test)
    end

    it "should allow a new default delivery_method to be set" do
      subject.default_delivery_method = :test
      expect(subject.delivery_method).to eq(:test)
    end

    it "should allow the delivery_method to be set over a default" do
      subject.default_delivery_method = :test
      subject.delivery_method = :wow
      expect(subject.delivery_method).to eq(:wow)
    end
  end

  describe "release_stage" do
    after(:each) do
      ENV["BUGSNAG_RELEASE_STAGE"] = nil
    end

    it "has no default value" do
      expect(subject.release_stage).to be_nil
    end

    it "uses the 'BUGSNAG_RELEASE_STAGE' environment variable if set" do
      ENV["BUGSNAG_RELEASE_STAGE"] = "foobar"
      expect(subject.release_stage).to eq("foobar")
    end
  end

  describe "app_type" do
    it "should default to nil" do
      expect(subject.app_type).to be_nil
    end

    it "should be settable directly" do
      subject.app_type = :test
      expect(subject.app_type).to eq(:test)
    end

    it "should allow a detected app_type to be set" do
      subject.detected_app_type = :test
      expect(subject.app_type).to eq(:test)
    end

    it "should allow the app_type to be set over a default" do
      subject.detected_app_type = :test
      subject.app_type = :wow
      expect(subject.app_type).to eq(:wow)
    end
  end

  describe "context" do
    it "should default to nil" do
      expect(subject.context).to be_nil
    end

    it "should be settable" do
      subject.context = "test"
      expect(subject.context).to eq("test")
    end
  end

  describe "#auto_capture_sessions" do
    it "defaults to true" do
      expect(subject.auto_capture_sessions).to eq(true)
    end
  end

  describe "#auto_track_sessions" do
    it "defaults to true" do
      expect(subject.auto_track_sessions).to eq(true)
    end

    it "shares a backing boolean with 'auto_capture_sessions'" do
      subject.auto_track_sessions = false
      expect(subject.auto_track_sessions).to eq(false)
      expect(subject.auto_capture_sessions).to eq(false)

      subject.auto_capture_sessions = true
      expect(subject.auto_track_sessions).to eq(true)
      expect(subject.auto_capture_sessions).to eq(true)
    end
  end

  describe "#enable_sessions" do
    it "defaults to true" do
      expect(subject.enable_sessions).to eq(true)
    end

    it "is readonly" do
      expect{ subject.enable_sessions = true }.to raise_error(NoMethodError)
    end
  end

  describe "endpoint configuration" do
    describe "#notify_endpoint" do
      it "defaults to DEFAULT_NOTIFY_ENDPOINT" do
        expect(subject.notify_endpoint).to eq(Bugsnag::Configuration::DEFAULT_NOTIFY_ENDPOINT)
      end

      it "is readonly" do
        expect{ subject.notify_endpoint = "My Custom Url" }.to raise_error(NoMethodError)
      end

      it "is the same as endpoint" do
        expect(subject.notify_endpoint).to equal(subject.endpoint)
      end
    end

    describe "#session_endpoint" do
      it "defaults to DEFAULT_SESSION_ENDPOINT" do
        expect(subject.session_endpoint).to eq(Bugsnag::Configuration::DEFAULT_SESSION_ENDPOINT)
      end
    end

    describe "#endpoint=" do
      let(:custom_notify_endpoint) { "My custom notify endpoint" }
      let(:session_endpoint) { "My session endpoint" }
      it "calls #warn with a deprecation notice" do
        allow(subject).to receive(:set_endpoints)
        expect(subject).to receive(:warn).with("The 'endpoint' configuration option is deprecated. Set both endpoints with the 'endpoints=' method instead")
        subject.endpoint = custom_notify_endpoint
      end

      it "calls #set_endpoints with the new notify_endpoint and existing session endpoint" do
        allow(subject).to receive(:session_endpoint).and_return(session_endpoint)
        allow(subject).to receive(:warn)
        expect(subject).to receive(:set_endpoints).with(custom_notify_endpoint, session_endpoint)
        subject.endpoint = custom_notify_endpoint
      end
    end

    describe "#session_endpoint=" do
      let(:notify_endpoint) { "My notify endpoint" }
      let(:custom_session_endpoint) { "My custom session endpoint" }
      it "calls #warn with a deprecation notice" do
        allow(subject).to receive(:set_endpoints)
        expect(subject).to receive(:warn).with("The 'session_endpoint' configuration option is deprecated. Set both endpoints with the 'endpoints=' method instead")
        subject.session_endpoint = custom_session_endpoint
      end

      it "calls #set_endpoints with the existing notify_endpoint and new session endpoint" do
        allow(subject).to receive(:notify_endpoint).and_return(notify_endpoint)
        allow(subject).to receive(:warn)
        expect(subject).to receive(:set_endpoints).with(notify_endpoint, custom_session_endpoint)
        subject.session_endpoint = custom_session_endpoint
      end
    end

    describe "#set_endpoints" do
      let(:custom_notify_endpoint) { "My custom notify endpoint" }
      let(:custom_session_endpoint) { "My custom session endpoint" }
      it "set notify_endpoint and session_endpoint" do
        subject.set_endpoints(custom_notify_endpoint, custom_session_endpoint)
        expect(subject.notify_endpoint).to eq(custom_notify_endpoint)
        expect(subject.session_endpoint).to eq(custom_session_endpoint)
      end
    end

    describe "#endpoints" do
      it "defaults to 'DEFAULT_NOTIFY_ENDPOINT' & 'DEFAULT_SESSION_ENDPOINT'" do
        config = Bugsnag::Configuration.new

        expect(config.endpoints.notify).to eq(Bugsnag::Configuration::DEFAULT_NOTIFY_ENDPOINT)
        expect(config.endpoints.sessions).to eq(Bugsnag::Configuration::DEFAULT_SESSION_ENDPOINT)
      end
    end

    describe "#endpoints=" do
      it "can be set with an EndpointConfiguration" do
        config = Bugsnag::Configuration.new
        expect(config).not_to receive(:warn)

        config.endpoints = Bugsnag::EndpointConfiguration.new("notify.example.com", "sessions.example.com")

        expect(config.endpoints.notify).to eq("notify.example.com")
        expect(config.endpoints.sessions).to eq("sessions.example.com")
      end

      it "warns and disables all sending if the no URLs are given" do
        config = Bugsnag::Configuration.new
        expect(config).to receive(:warn).with(Bugsnag::EndpointValidator::Result::MISSING_URLS)

        config.endpoints = Bugsnag::EndpointConfiguration.new(nil, nil)

        expect(config.endpoints.notify).to be_nil
        expect(config.endpoints.sessions).to be_nil

        expect(config.enable_events).to be(false)
        expect(config.enable_sessions).to be(false)
      end

      # TODO: this behaviour exists for backwards compatibilitiy
      #       ideally we should not send events in this case
      it "warns and disables sessions if only notify URL is given" do
        config = Bugsnag::Configuration.new
        expect(config).to receive(:warn).with(Bugsnag::EndpointValidator::Result::MISSING_SESSION_URL)

        config.endpoints = Bugsnag::EndpointConfiguration.new("notify.example.com", nil)

        expect(config.endpoints.notify).to eq("notify.example.com")
        expect(config.endpoints.sessions).to be_nil

        expect(config.enable_events).to be(true)
        expect(config.enable_sessions).to be(false)
      end

      it "warns and disables events and sessions if only session URL is given" do
        config = Bugsnag::Configuration.new
        expect(config).to receive(:warn).with(Bugsnag::EndpointValidator::Result::MISSING_NOTIFY_URL)

        config.endpoints = Bugsnag::EndpointConfiguration.new(nil, "sessions.example.com")

        expect(config.endpoints.notify).to be_nil
        expect(config.endpoints.sessions).to eq("sessions.example.com")

        expect(config.enable_events).to be(false)
        expect(config.enable_sessions).to be(false)
      end

      it "re-enables sessions if valid URLs are given after only giving notify URL" do
        config = Bugsnag::Configuration.new
        expect(config).to receive(:warn).with(Bugsnag::EndpointValidator::Result::MISSING_SESSION_URL)

        config.endpoints = Bugsnag::EndpointConfiguration.new("notify.example.com", nil)

        expect(config.enable_events).to be(true)
        expect(config.enable_sessions).to be(false)

        config.endpoints = Bugsnag::EndpointConfiguration.new("notify.example.com", "sessions.example.com")

        expect(config.endpoints.notify).to eq("notify.example.com")
        expect(config.endpoints.sessions).to eq("sessions.example.com")

        expect(config.enable_events).to be(true)
        expect(config.enable_sessions).to be(true)
      end

      it "re-enables events and sessions if valid URLs are given after only giving session URL" do
        config = Bugsnag::Configuration.new
        expect(config).to receive(:warn).with(Bugsnag::EndpointValidator::Result::MISSING_NOTIFY_URL)

        config.endpoints = Bugsnag::EndpointConfiguration.new(nil, "sessions.example.com")

        expect(config.enable_events).to be(false)
        expect(config.enable_sessions).to be(false)

        config.endpoints = Bugsnag::EndpointConfiguration.new("notify.example.com", "sessions.example.com")

        expect(config.endpoints.notify).to eq("notify.example.com")
        expect(config.endpoints.sessions).to eq("sessions.example.com")

        expect(config.enable_events).to be(true)
        expect(config.enable_sessions).to be(true)
      end
    end
  end

  describe "#disable_sessions" do
    it "sets #send_session and #auto_capture_sessions to false" do
      subject.disable_sessions
      expect(subject.auto_capture_sessions).to be false
      expect(subject.enable_sessions).to be false
    end
  end

  describe "set_proxy" do
    it "defaults proxy settings to nil" do
      expect(subject.proxy_host).to be nil
      expect(subject.proxy_port).to be nil
      expect(subject.proxy_user).to be nil
      expect(subject.proxy_password).to be nil
    end

    it "allows proxy settings to be set directly" do
      subject.proxy_host = "http://localhost"
      subject.proxy_port = 34000
      subject.proxy_user = "user"
      subject.proxy_password = "password"
      expect(subject.proxy_host).to eq("http://localhost")
      expect(subject.proxy_port).to eq(34000)
      expect(subject.proxy_user).to eq("user")
      expect(subject.proxy_password).to eq("password")
    end

    it "parses a uri if provided" do
      subject.parse_proxy("http://user:password@localhost:34000")
      expect(subject.proxy_host).to eq("localhost")
      expect(subject.proxy_port).to eq(34000)
      expect(subject.proxy_user).to eq("user")
      expect(subject.proxy_password).to eq("password")
    end

    it "automatically parses http_proxy environment variable" do
      ENV['http_proxy'] = "http://user:password@localhost:34000"
      expect(subject.proxy_host).to eq("localhost")
      expect(subject.proxy_port).to eq(34000)
      expect(subject.proxy_user).to eq("user")
      expect(subject.proxy_password).to eq("password")
    end

    it "automatically parses https_proxy environment variable" do
      ENV['https_proxy'] = "https://user:password@localhost:34000"
      expect(subject.proxy_host).to eq("localhost")
      expect(subject.proxy_port).to eq(34000)
      expect(subject.proxy_user).to eq("user")
      expect(subject.proxy_password).to eq("password")
    end

    after do
      ENV['http_proxy'] = nil
      ENV['https_proxy'] = nil
    end
  end

  describe "#hostname" do
    it "has a default value" do
      expect(subject.hostname.length).to be > 0
    end

    it "has a value set by Socket" do
      expect(subject.hostname).to eq(Socket.gethostname)
    end

    it "has a value set by DYNO environment variable" do
      ENV['DYNO'] = 'localhost'
      expect(subject.hostname).to eq("localhost")
    end

    after do
      ENV['DYNO'] = nil
    end
  end

  describe "#runtime_versions" do
    it "has a default value" do
      expect(subject.runtime_versions.length).to be > 0
      expect(subject.runtime_versions["ruby"]).to eq(RUBY_VERSION)
    end

    it "has a settable value" do
      subject.runtime_versions["ruby"] = '9.9.9'
      expect(subject.runtime_versions["ruby"]).to eq('9.9.9')
    end
  end

  describe "logger" do
    before do
      @output = StringIO.new
      @formatter = proc do |severity, _datetime, progname, message|
        "#{progname} #{severity}: #{message}"
      end

      logger = Logger.new(@output)
      logger.formatter = @formatter

      Bugsnag.configuration.logger = logger
    end

    def output_lines
      @output.rewind # always read from the start of output
      @output.readlines.map(&:chomp) # old rubies don't support `readlines(chomp: true)`
    end

    context "using configure" do
      before do
        Bugsnag.configuration.api_key = nil
        Bugsnag.instance_variable_set("@key_warning", nil)
        ENV['BUGSNAG_API_KEY'] = nil
        expect(output_lines).to be_empty
      end

      context "API key is not specified" do
        it "skips logging a warning if validate_api_key is false" do
          Bugsnag.configure(false)
          expect(output_lines).to be_empty
        end

        it "logs a warning by default" do
          Bugsnag.configure

          expect(output_lines.length).to be(1)
          expect(output_lines.first).to eq(
            '[Bugsnag] WARN: No valid API key has been set, notifications will not be sent'
          )
        end

        it "logs a warning if validate_api_key is true" do
          Bugsnag.configure(true)

          expect(output_lines.length).to be(1)
          expect(output_lines.first).to eq(
            '[Bugsnag] WARN: No valid API key has been set, notifications will not be sent'
          )
        end
      end

      context "API key is set" do
        it "skips logging a warning when configuring with an API key" do
          Bugsnag.configure do |config|
            config.api_key = 'd57a2472bd130ac0ab0f52715bbdc600'
          end

          expect(output_lines).to be_empty
        end

        it "logs a warning if the configured API key is invalid" do
          Bugsnag.configure do |config|
            config.api_key = 'WARNING: not a real key'
          end

          expect(output_lines.length).to be(1)
          expect(output_lines.first).to eq(
            '[Bugsnag] WARN: No valid API key has been set, notifications will not be sent'
          )
        end
      end
    end

    it "should log info messages to the set logger" do
      expect(output_lines).to be_empty

      Bugsnag.configuration.info("Info message")

      expect(output_lines.length).to be(1)
      expect(output_lines.first).to eq('[Bugsnag] INFO: Info message')
    end

    it "should log warning messages to the set logger" do
      expect(output_lines).to be_empty

      Bugsnag.configuration.warn("Warning message")

      expect(output_lines.length).to be(1)
      expect(output_lines.first).to eq('[Bugsnag] WARN: Warning message')
    end

    it "should log error messages to the set logger" do
      expect(output_lines).to be_empty

      Bugsnag.configuration.error("Error message")

      expect(output_lines.length).to be(1)
      expect(output_lines.first).to eq('[Bugsnag] ERROR: Error message')
    end

    it "should log debug messages to the set logger" do
      expect(output_lines).to be_empty

      Bugsnag.configuration.debug("Debug message")

      expect(output_lines.length).to be(1)
      expect(output_lines.first).to eq('[Bugsnag] DEBUG: Debug message')
    end
  end

  it "should have exit exception classes in ignore_classes by default" do
    expect(subject.ignore_classes).to eq(Set.new([SystemExit, SignalException]))
  end

  it "should have nothing in discard_classes by default" do
    expect(subject.discard_classes).to eq(Set.new([]))
  end

  describe "#breadcrumbs" do
    it "first returns a new circular buffer" do
      buffer = subject.breadcrumbs

      expect(buffer).to be_a(Bugsnag::Utility::CircularBuffer)
      expect(buffer.to_a).to eq([])
    end

    it "returns the same buffer in repeated calls" do
      buffer = subject.breadcrumbs
      buffer << 1
      second_buffer = subject.breadcrumbs

      expect(second_buffer.to_a).to eq([1])
    end

    it "returns a different buffer on different threads" do
      buffer = subject.breadcrumbs
      buffer << 1

      second_buffer = nil
      Thread.new { second_buffer = subject.breadcrumbs; second_buffer << 2 }.join

      expect(buffer.to_a).to eq([1])
      expect(second_buffer.to_a).to eq([2])
    end

    it "sets max_items to the current max_breadcrumbs size" do
      expect(subject.breadcrumbs.max_items).to eq(subject.max_breadcrumbs)
    end
  end

  describe "#max_breadcrumbs" do
    it "defaults to DEFAULT_MAX_BREADCRUMBS" do
      expect(subject.max_breadcrumbs).to eq(Bugsnag::Configuration::DEFAULT_MAX_BREADCRUMBS)
    end
  end

  describe "#max_breadcrumbs=" do
    it "sets the value of max_breadcrumbs" do
      subject.max_breadcrumbs = 10
      expect(subject.max_breadcrumbs).to eq(10)
    end

    it "sets the max_items property of the breadcrumbs buffer" do
      buffer = subject.breadcrumbs

      expect(buffer.max_items).to eq(Bugsnag::Configuration::DEFAULT_MAX_BREADCRUMBS)

      subject.max_breadcrumbs = 5

      expect(buffer.max_items).to eq(5)
    end
  end

  describe "#enabled_automatic_breadcrumb_types" do
    it "defaults to Bugsnag::Breadcrumbs::VALID_BREADCRUMB_TYPES" do
      expect(subject.enabled_automatic_breadcrumb_types).to eq(Bugsnag::Breadcrumbs::VALID_BREADCRUMB_TYPES)
    end

    it "is an editable array" do
      subject.enabled_automatic_breadcrumb_types << "Some custom type"
      expect(subject.enabled_automatic_breadcrumb_types).to include("Some custom type")
    end
  end

  describe "#enabled_breadcrumb_types" do
    it "defaults to Bugsnag::Breadcrumbs::VALID_BREADCRUMB_TYPES" do
      expect(subject.enabled_breadcrumb_types).to eq(Bugsnag::Breadcrumbs::VALID_BREADCRUMB_TYPES)
    end

    it "is an editable array" do
      subject.enabled_breadcrumb_types << "Some custom type"
      expect(subject.enabled_breadcrumb_types).to include("Some custom type")
    end

    it "shares a backing array with 'enabled_automatic_breadcrumb_types'" do
      expect(subject.enabled_breadcrumb_types).to be(subject.enabled_automatic_breadcrumb_types)

      subject.enabled_breadcrumb_types = [1, 2, 3]
      expect(subject.enabled_breadcrumb_types).to eq([1, 2, 3])
      expect(subject.enabled_automatic_breadcrumb_types).to eq([1, 2, 3])

      subject.enabled_automatic_breadcrumb_types = [4, 5, 6]
      expect(subject.enabled_breadcrumb_types).to eq([4, 5, 6])
      expect(subject.enabled_automatic_breadcrumb_types).to eq([4, 5, 6])
    end
  end

  describe "#before_breadcrumb_callbacks" do
    it "initially returns an empty array" do
      expect(subject.before_breadcrumb_callbacks).to eq([])
    end

    it "stores the array between subsequent calls" do
      first_call = subject.before_breadcrumb_callbacks
      first_call << 1

      second_call = subject.before_breadcrumb_callbacks

      expect(second_call).to eq([1])
    end

    it "stays the same across threads" do
      first_array = subject.before_breadcrumb_callbacks
      first_array << 1

      second_array = nil
      Thread.new { second_array = subject.before_breadcrumb_callbacks; second_array << 2}.join

      expect(first_array).to eq([1, 2])
      expect(second_array).to eq([1, 2])
    end
  end

  describe "#vendor_path" do
    it "returns the default vendor path" do
      expect(subject.vendor_path).to eq(Bugsnag::Configuration::DEFAULT_VENDOR_PATH)
    end

    it "returns the defined vendor path" do
      subject.vendor_path = /foo/
      expect(subject.vendor_path).to eq(/foo/)
    end
  end

  describe "metadata" do
    include_examples(
      "metadata delegate",
      lambda do |metadata, *args|
        configuration = Bugsnag::Configuration.new
        configuration.instance_variable_set(:@metadata, metadata)

        configuration.add_metadata(*args)
      end,
      lambda do |metadata, *args|
        configuration = Bugsnag::Configuration.new
        configuration.instance_variable_set(:@metadata, metadata)

        configuration.clear_metadata(*args)
      end
    )

    describe "#metadata" do
      it "is initially empty" do
        expect(subject.metadata).to be_empty
      end

      it "cannot be reassigned" do
        expect(subject).not_to respond_to(:metadata=)
      end

      it "reflects changes made by add_/clear_metadata" do
        subject.add_metadata(:abc, { a: 1, b: 2, c: 3 })
        subject.add_metadata(:xyz, :x, 1)

        expect(subject.metadata).to eq({ abc: { a: 1, b: 2, c: 3 }, xyz: { x: 1 } })

        subject.clear_metadata(:abc)

        expect(subject.metadata).to eq({ xyz: { x: 1 } })
      end
    end

    describe "concurrent access" do
      it "can handle multiple threads adding metadata" do
        configuration = Bugsnag::Configuration.new

        threads = 5.times.map do |i|
          Thread.new do
            configuration.add_metadata(:abc, "thread_#{i}", i)
          end
        end

        threads += 5.times.map do |i|
          Thread.new do
            configuration.add_metadata(:xyz, {
              "thread_#{i}" => i * 100,
              "also thread_#{i}" => [i, i + 1, i + 2],
            })
          end
        end

        threads.shuffle.map(&:join)

        expect(configuration.metadata).to eq({
          abc: {
            "thread_0" => 0,
            "thread_1" => 1,
            "thread_2" => 2,
            "thread_3" => 3,
            "thread_4" => 4,
          },
          xyz: {
            "thread_0" => 0,
            "thread_1" => 100,
            "thread_2" => 200,
            "thread_3" => 300,
            "thread_4" => 400,
            "also thread_0" => [0, 1, 2],
            "also thread_1" => [1, 2, 3],
            "also thread_2" => [2, 3, 4],
            "also thread_3" => [3, 4, 5],
            "also thread_4" => [4, 5, 6],
          }
        })
      end

      it "can handle multiple threads clearing metadata" do
        configuration = Bugsnag::Configuration.new

        configuration.add_metadata(:abc, { a: 1, b: 2, c: 3 })
        configuration.add_metadata(:xyz, { 0 => 0, 1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5 })

        5.times do |i|
          configuration.add_metadata("thread_#{i}", :i, i)
        end

        threads = 5.times.map do |i|
          Thread.new do
            configuration.clear_metadata("thread_#{i}")
            configuration.clear_metadata(:xyz, i)
          end
        end

        threads += 5.times.map do |i|
          Thread.new do
            configuration.clear_metadata(:xyz)
          end
        end

        threads.shuffle.map(&:join)

        expect(configuration.metadata).to eq({ abc: { a: 1, b: 2, c: 3 } })
      end
    end
  end

  describe "feature flags" do
    describe "#feature_flag_delegate" do
      it "is initially empty" do
        expect(subject.feature_flag_delegate.to_a).to be_empty
      end

      it "cannot be reassigned" do
        expect(subject).not_to respond_to(:feature_flag_delegate=)
      end

      it "reflects changes in add/clear feature flags" do
        subject.add_feature_flag('abc')
        subject.add_feature_flags([
          Bugsnag::FeatureFlag.new('1'),
          Bugsnag::FeatureFlag.new('2', 'z'),
          Bugsnag::FeatureFlag.new('3'),
        ])
        subject.add_feature_flag('xyz', '1234')

        subject.clear_feature_flag('3')

        expect(subject.feature_flag_delegate.to_a).to eq([
          Bugsnag::FeatureFlag.new('abc'),
          Bugsnag::FeatureFlag.new('1'),
          Bugsnag::FeatureFlag.new('2', 'z'),
          Bugsnag::FeatureFlag.new('xyz', '1234'),
        ])

        subject.clear_feature_flags

        expect(subject.feature_flag_delegate.to_a).to be_empty
      end
    end

    describe "concurrent access" do
      it "can handle multiple threads adding feature flags" do
        configuration = Bugsnag::Configuration.new

        threads = 5.times.map do |i|
          Thread.new do
            configuration.add_feature_flag("thread_#{i} flag 1", i)
          end
        end

        threads += 5.times.map do |i|
          Thread.new do
            configuration.add_feature_flags([
              Bugsnag::FeatureFlag.new("thread_#{i} flag 2", i * 100),
              Bugsnag::FeatureFlag.new("thread_#{i} flag 3", i * 100 + 1),
            ])
          end
        end

        threads.shuffle.map(&:join)

        flags = configuration.feature_flag_delegate.to_a.sort do |a, b|
          a.name <=> b.name
        end

        expect(flags).to eq([
          Bugsnag::FeatureFlag.new('thread_0 flag 1', 0),
          Bugsnag::FeatureFlag.new('thread_0 flag 2', 0),
          Bugsnag::FeatureFlag.new('thread_0 flag 3', 1),
          Bugsnag::FeatureFlag.new('thread_1 flag 1', 1),
          Bugsnag::FeatureFlag.new('thread_1 flag 2', 100),
          Bugsnag::FeatureFlag.new('thread_1 flag 3', 101),
          Bugsnag::FeatureFlag.new('thread_2 flag 1', 2),
          Bugsnag::FeatureFlag.new('thread_2 flag 2', 200),
          Bugsnag::FeatureFlag.new('thread_2 flag 3', 201),
          Bugsnag::FeatureFlag.new('thread_3 flag 1', 3),
          Bugsnag::FeatureFlag.new('thread_3 flag 2', 300),
          Bugsnag::FeatureFlag.new('thread_3 flag 3', 301),
          Bugsnag::FeatureFlag.new('thread_4 flag 1', 4),
          Bugsnag::FeatureFlag.new('thread_4 flag 2', 400),
          Bugsnag::FeatureFlag.new('thread_4 flag 3', 401),
        ])
      end

      it "can handle multiple threads clearing feature flags" do
        configuration = Bugsnag::Configuration.new

        configuration.add_feature_flag('abc')
        configuration.add_feature_flag('xyz')

        5.times do |i|
          configuration.add_feature_flag("thread_#{i}", i)
        end

        threads = 5.times.map do |i|
          Thread.new do
            configuration.clear_feature_flag("thread_#{i}")
            configuration.clear_feature_flag('abc')
            configuration.clear_feature_flag('xyz')
          end
        end

        threads.shuffle.map(&:join)

        expect(configuration.feature_flag_delegate.to_a).to be_empty
      end
    end
  end
end
