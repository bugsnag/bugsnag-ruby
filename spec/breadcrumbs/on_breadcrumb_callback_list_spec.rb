require "spec_helper"

require "bugsnag/breadcrumbs/on_breadcrumb_callback_list"

RSpec.describe Bugsnag::Breadcrumbs::OnBreadcrumbCallbackList do
  it "can add callbacks to its list" do
    callback = spy('callback')

    list = Bugsnag::Breadcrumbs::OnBreadcrumbCallbackList.new(Bugsnag.configuration)
    list.add(callback)

    breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new('name', 'type', {}, nil)

    list.call(breadcrumb)

    expect(callback).to have_received(:call).with(breadcrumb)
    expect(breadcrumb.ignore?).to be(false)
  end

  it "can remove callbacks to its list" do
    callback = spy('callback')

    list = Bugsnag::Breadcrumbs::OnBreadcrumbCallbackList.new(Bugsnag.configuration)
    list.add(callback)
    list.remove(callback)

    breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new('name', 'type', {}, nil)

    list.call(breadcrumb)

    expect(callback).not_to have_received(:call)
    expect(breadcrumb.ignore?).to be(false)
  end

  it "won't remove a callback that isn't the same instance" do
    callback1 = spy('callback1')
    callback2 = spy('callback2')

    list = Bugsnag::Breadcrumbs::OnBreadcrumbCallbackList.new(Bugsnag.configuration)

    # note: adding callback1 but removing callback2
    list.add(callback1)
    list.remove(callback2)

    breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new('name', 'type', {}, nil)

    list.call(breadcrumb)

    expect(callback1).to have_received(:call).with(breadcrumb)
    expect(callback2).not_to have_received(:call)
    expect(breadcrumb.ignore?).to be(false)
  end

  it "calls callbacks in the order they were added" do
    calls = []

    list = Bugsnag::Breadcrumbs::OnBreadcrumbCallbackList.new(Bugsnag.configuration)

    list.add(proc { calls << 1 })
    list.add(proc { calls << 2 })
    list.add(proc { calls << 3 })

    breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new('name', 'type', {}, nil)

    list.call(breadcrumb)

    expect(calls).to eq([1, 2, 3])
    expect(breadcrumb.ignore?).to be(false)
  end

  it "ignores the breadcrumb if a callback returns false" do
    list = Bugsnag::Breadcrumbs::OnBreadcrumbCallbackList.new(Bugsnag.configuration)

    list.add(proc { false })

    breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new('name', 'type', {}, nil)

    list.call(breadcrumb)

    expect(breadcrumb.ignore?).to be(true)
  end

  it "does not ignore the breadcrumb if a callback returns nil" do
    list = Bugsnag::Breadcrumbs::OnBreadcrumbCallbackList.new(Bugsnag.configuration)

    list.add(proc { nil })

    breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new('name', 'type', {}, nil)

    list.call(breadcrumb)

    expect(breadcrumb.ignore?).to be(false)
  end

  it "supports Method objects as callbacks" do
    class ArbitraryClassMethod
      def self.arbitrary_name(breadcrumb)
        breadcrumb.metadata[:abc] = 123
      end
    end

    class ArbitraryInstanceMethod
      def arbitrary_name(breadcrumb)
        breadcrumb.metadata[:xyz] = 789
      end
    end

    list = Bugsnag::Breadcrumbs::OnBreadcrumbCallbackList.new(Bugsnag.configuration)

    list.add(ArbitraryClassMethod.method(:arbitrary_name))

    xyz = ArbitraryInstanceMethod.new
    list.add(xyz.method(:arbitrary_name))

    breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new('name', 'type', {}, nil)

    list.call(breadcrumb)

    expect(breadcrumb.metadata).to eq({ abc: 123, xyz: 789 })
  end

  it "allows removing Method objects as callbacks" do
    class ArbitraryClassMethod
      def self.arbitrary_name(breadcrumb)
        breadcrumb.metadata[:abc] = 123
      end
    end

    class ArbitraryInstanceMethod
      def arbitrary_name(breadcrumb)
        breadcrumb.metadata[:xyz] = 789
      end
    end

    list = Bugsnag::Breadcrumbs::OnBreadcrumbCallbackList.new(Bugsnag.configuration)

    list.add(ArbitraryClassMethod.method(:arbitrary_name))
    list.remove(ArbitraryClassMethod.method(:arbitrary_name))

    xyz = ArbitraryInstanceMethod.new
    list.add(xyz.method(:arbitrary_name))
    list.remove(xyz.method(:arbitrary_name))

    breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new('name', 'type', {}, nil)

    list.call(breadcrumb)

    expect(breadcrumb.metadata).to eq({})
  end

  it "supports arbitrary objects that respond to #call as callbacks" do
    class RespondsToCallAsClassMethod
      def self.call(breadcrumb)
        breadcrumb.metadata[:abc] = 123
      end
    end

    class RespondsToCallAsInstanceMethod
      def call(breadcrumb)
        breadcrumb.metadata[:xyz] = 789
      end
    end

    list = Bugsnag::Breadcrumbs::OnBreadcrumbCallbackList.new(Bugsnag.configuration)

    list.add(RespondsToCallAsClassMethod)
    list.add(RespondsToCallAsInstanceMethod.new)

    breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new('name', 'type', {}, nil)

    list.call(breadcrumb)

    expect(breadcrumb.metadata).to eq({ abc: 123, xyz: 789 })
  end

  it "supports removing arbitrary objects that respond to #call as callbacks" do
    class RespondsToCallAsClassMethod
      def self.call(breadcrumb)
        breadcrumb.metadata[:abc] = 123
      end
    end

    class RespondsToCallAsInstanceMethod
      def call(breadcrumb)
        breadcrumb.metadata[:xyz] = 789
      end
    end

    list = Bugsnag::Breadcrumbs::OnBreadcrumbCallbackList.new(Bugsnag.configuration)

    list.add(RespondsToCallAsClassMethod)
    list.remove(RespondsToCallAsClassMethod)

    instance = RespondsToCallAsInstanceMethod.new
    list.add(instance)
    list.remove(instance)

    breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new('name', 'type', {}, nil)

    list.call(breadcrumb)

    expect(breadcrumb.metadata).to eq({})
  end

  it "works when accessed concurrently" do
    list = Bugsnag::Breadcrumbs::OnBreadcrumbCallbackList.new(Bugsnag.configuration)

    list.add(proc do |breadcrumb|
      breadcrumb.metadata[:numbers] = []
    end)

    NUMBER_OF_THREADS = 20

    threads = NUMBER_OF_THREADS.times.map do |i|
      Thread.new do
        list.add(proc do |breadcrumb|
          breadcrumb.metadata[:numbers].push(i)
        end)
      end
    end

    threads.shuffle.each(&:join)

    breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new('name', 'type', {}, nil)
    list.call(breadcrumb)

    # sort the numbers as they will be out of order but that doesn't matter as
    # long as every number is present
    expect(breadcrumb.metadata[:numbers].sort).to eq((0...NUMBER_OF_THREADS).to_a)
  end

  it "logs errors thrown in callbacks" do
    logger = spy('logger')
    Bugsnag.configuration.logger = logger

    list = Bugsnag::Breadcrumbs::OnBreadcrumbCallbackList.new(Bugsnag.configuration)
    error = RuntimeError.new('Oh no!')

    list.add(proc { raise error })

    breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new('name', 'type', {}, nil)

    list.call(breadcrumb)

    expect(breadcrumb.ignore?).to be(false)

    message_index = 0
    expected_messages = [
      /^Error occurred in on_breadcrumb callback: 'Oh no!'$/,
      /^on_breadcrumb callback stacktrace:/
    ]

    expect(logger).to have_received(:warn).with("[Bugsnag]").twice do |&block|
      expect(block.call).to match(expected_messages[message_index])
      message_index += 1
    end
  end

  it "calls subsequent callbacks after an error is raised" do
    list = Bugsnag::Breadcrumbs::OnBreadcrumbCallbackList.new(Bugsnag.configuration)
    calls = []

    list.add(proc { calls << 1 })
    list.add(proc { calls << 2 })
    list.add(proc { raise 'ab' })
    list.add(proc { calls << 4 })
    list.add(proc { calls << 5 })

    breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new('name', 'type', {}, nil)

    list.call(breadcrumb)

    expect(calls).to eq([1, 2, 4, 5])
    expect(breadcrumb.ignore?).to be(false)
  end
end
