require "spec_helper"

describe "on_error callbacks" do
  it "runs callbacks on notify" do
    callback1 = proc {|report| report.add_tab(:important, { hello: "world" }) }
    callback2 = proc {|report| report.add_tab(:significant, { hey: "earth" }) }

    Bugsnag.add_on_error(callback1)
    Bugsnag.add_on_error(callback2)

    Bugsnag.notify(RuntimeError.new("Oh no!"))

    expect(Bugsnag).to(have_sent_notification do |payload, _headers|
      event = get_event_from_payload(payload)

      expect(event["metaData"]["important"]).to eq({ "hello" => "world" })
      expect(event["metaData"]["significant"]).to eq({ "hey" => "earth" })
    end)
  end

  it "can add callbacks in a configure block" do
    callback1 = proc {|report| report.add_tab(:important, { hello: "world" }) }
    callback2 = proc {|report| report.add_tab(:significant, { hey: "earth" }) }

    Bugsnag.configure do |config|
      config.add_on_error(callback1)
      config.add_on_error(callback2)
    end

    Bugsnag.notify(RuntimeError.new("Oh no!"))

    expect(Bugsnag).to(have_sent_notification do |payload, _headers|
      event = get_event_from_payload(payload)

      expect(event["metaData"]["important"]).to eq({ "hello" => "world" })
      expect(event["metaData"]["significant"]).to eq({ "hey" => "earth" })
    end)
  end

  it "can remove an already registered callback" do
    callback1 = proc {|report| report.add_tab(:important, { hello: "world" }) }
    callback2 = proc {|report| report.add_tab(:significant, { hey: "earth" }) }

    Bugsnag.add_on_error(callback1)
    Bugsnag.add_on_error(callback2)

    Bugsnag.remove_on_error(callback1)

    Bugsnag.notify(RuntimeError.new("Oh no!"))

    expect(Bugsnag).to(have_sent_notification do |payload, _headers|
      event = get_event_from_payload(payload)

      expect(event["metaData"]["important"]).to be_nil
      expect(event["metaData"]["significant"]).to eq({ "hey" => "earth" })
    end)
  end

  it "can remove all registered callbacks" do
    callback1 = proc {|report| report.add_tab(:important, { hello: "world" }) }
    callback2 = proc {|report| report.add_tab(:significant, { hey: "earth" }) }

    Bugsnag.add_on_error(callback1)
    Bugsnag.add_on_error(callback2)

    Bugsnag.remove_on_error(callback2)
    Bugsnag.remove_on_error(callback1)

    Bugsnag.notify(RuntimeError.new("Oh no!"))

    expect(Bugsnag).to(have_sent_notification do |payload, _headers|
      event = get_event_from_payload(payload)

      expect(event["metaData"]["important"]).to be_nil
      expect(event["metaData"]["significant"]).to be_nil
    end)
  end

  it "does not remove an identical callback if it is not the same Proc" do
    callback1 = proc {|report| report.add_tab(:important, { hello: "world" }) }
    callback1_duplicate = proc {|report| report.add_tab(:important, { hello: "world" }) }

    Bugsnag.add_on_error(callback1)
    Bugsnag.remove_on_error(callback1_duplicate)

    Bugsnag.notify(RuntimeError.new("Oh no!"))

    expect(Bugsnag).to(have_sent_notification do |payload, _headers|
      event = get_event_from_payload(payload)

      expect(event["metaData"]["important"]).to eq({ "hello" => "world" })
    end)
  end

  it "can re-add callbacks that have previously been removed" do
    callback1 = proc {|report| report.add_tab(:important, { hello: "world" }) }
    callback2 = proc {|report| report.add_tab(:significant, { hey: "earth" }) }

    Bugsnag.add_on_error(callback1)
    Bugsnag.add_on_error(callback2)

    Bugsnag.remove_on_error(callback1)

    Bugsnag.add_on_error(callback1)

    Bugsnag.notify(RuntimeError.new("Oh no!"))

    expect(Bugsnag).to(have_sent_notification do |payload, _headers|
      event = get_event_from_payload(payload)

      expect(event["metaData"]["important"]).to eq({ "hello" => "world" })
      expect(event["metaData"]["significant"]).to eq({ "hey" => "earth" })
    end)
  end

  it "will only add a callback once" do
    called_count = 0

    callback = proc do |report|
      called_count += 1

      report.add_tab(:important, { called: called_count })
    end

    1.upto(10) do |i|
      Bugsnag.add_on_error(callback)
    end

    Bugsnag.notify(RuntimeError.new("Oh no!"))

    expect(Bugsnag).to(have_sent_notification do |payload, _headers|
      event = get_event_from_payload(payload)

      expect(called_count).to be(1)
      expect(event["metaData"]["important"]).to eq({ "called" => 1 })
    end)
  end

  it "will ignore the report and stop calling callbacks if one returns false" do
    logger = spy('logger')
    Bugsnag.configuration.logger = logger

    called_count = 0

    callback1 = proc { called_count += 1 }
    callback2 = proc { called_count += 1 }
    callback3 = proc { false }
    callback4 = proc { called_count += 1 }
    callback5 = proc { called_count += 1 }

    Bugsnag.add_on_error(callback1)
    Bugsnag.add_on_error(callback2)
    Bugsnag.add_on_error(callback3)
    Bugsnag.add_on_error(callback4)
    Bugsnag.add_on_error(callback5)

    Bugsnag.notify(RuntimeError.new("Oh no!"))

    expect(Bugsnag).not_to have_sent_notification
    expect(called_count).to be(2)

    expect(logger).to have_received(:debug).with("[Bugsnag]") do |&block|
      expect(block.call).to eq("Not notifying RuntimeError due to ignore being signified in user provided middleware")
    end
  end

  it "callbacks are called in the same order they are added (FIFO)" do
    callback1 = proc do |report|
      expect(report.meta_data[:important]).to be_nil

      report.add_tab(:important, { magic_number: 9 })
    end

    callback2 = proc do |report|
      expect(report.meta_data[:important]).to eq({ magic_number: 9 })

      report.add_tab(:important, { magic_number: 99 })
    end

    callback3 = proc do |report|
      expect(report.meta_data[:important]).to eq({ magic_number: 99 })

      report.add_tab(:important, { magic_number: 999 })
    end

    Bugsnag.add_on_error(callback1)
    Bugsnag.add_on_error(callback2)
    Bugsnag.add_on_error(callback3)

    Bugsnag.notify(RuntimeError.new("Oh no!"))

    expect(Bugsnag).to(have_sent_notification do |payload, _headers|
      event = get_event_from_payload(payload)

      expect(event["metaData"]["important"]).to eq({ "magic_number" => 999 })
    end)
  end

  it "callbacks continue being called after a callback raises" do
    logger = spy('logger')
    Bugsnag.configuration.logger = logger

    callback1 = proc {|report| report.add_tab(:important, { a: "b" }) }
    callback2 = proc {|_report| raise "bad things" }
    callback3 = proc {|report| report.add_tab(:important, { c: "d" }) }

    Bugsnag.add_on_error(callback1)
    Bugsnag.add_on_error(callback2)
    Bugsnag.add_on_error(callback3)

    Bugsnag.notify(RuntimeError.new("Oh no!"))

    expect(Bugsnag).to(have_sent_notification do |payload, _headers|
      event = get_event_from_payload(payload)

      expect(event["metaData"]["important"]).to eq({ "a" => "b", "c" => "d" })
    end)

    message_index = 0
    expected_messages = [
      /^Error occurred in on_error callback: 'bad things'$/,
      /^on_error callback stacktrace:/
    ]

    expect(logger).to have_received(:warn).with("[Bugsnag]").twice do |&block|
      expect(block.call).to match(expected_messages[message_index])
      message_index += 1
    end
  end

  it "runs callbacks even if no other middleware is registered" do
    # Reset the middleware stack so any default middleware are removed
    Bugsnag.configuration.middleware = Bugsnag::MiddlewareStack.new

    callback1 = proc {|report| report.add_tab(:important, { hello: "world" }) }
    callback2 = proc {|report| report.add_tab(:significant, { hey: "earth" }) }

    Bugsnag.add_on_error(callback1)
    Bugsnag.add_on_error(callback2)

    Bugsnag.notify(RuntimeError.new("Oh no!"))

    expect(Bugsnag).to(have_sent_notification do |payload, _headers|
      event = get_event_from_payload(payload)

      expect(event["metaData"]["important"]).to eq({ "hello" => "world" })
      expect(event["metaData"]["significant"]).to eq({ "hey" => "earth" })
    end)
  end

  describe "using callbacks across threads" do
    it "runs callbacks that are added in different threads" do
      callback1 = proc {|report| report.add_tab(:important, { hello: "world" }) }
      callback2 = proc {|report| report.add_tab(:significant, { hey: "earth" }) }
      callback3 = proc {|report| report.add_tab(:crucial, { magic_number: 999 }) }

      Bugsnag.add_on_error(callback1)

      threads = [
        Thread.new { Bugsnag.add_on_error(callback2) },
        Thread.new { Bugsnag.add_on_error(callback3) }
      ]

      threads.each(&:join)

      Bugsnag.notify(RuntimeError.new("Oh no!"))

      expect(Bugsnag).to(have_sent_notification do |payload, _headers|
        event = get_event_from_payload(payload)

        expect(event["metaData"]["important"]).to eq({ "hello" => "world" })
        expect(event["metaData"]["significant"]).to eq({ "hey" => "earth" })
        expect(event["metaData"]["crucial"]).to eq({ "magic_number" => 999 })
      end)
    end

    it "can remove callbacks that are added in different threads" do
      callback1 = proc {|report| report.add_tab(:important, { hello: "world" }) }
      callback2 = proc {|report| report.add_tab(:significant, { hey: "earth" }) }

      # We need to create & join these one at a time so that callback1 has
      # definitely been added before it is removed, otherwise this test will fail
      # at random
      Thread.new { Bugsnag.add_on_error(callback1) }.join
      Thread.new { Bugsnag.remove_on_error(callback1) }.join
      Thread.new { Bugsnag.add_on_error(callback2) }.join

      Bugsnag.notify(RuntimeError.new("Oh no!"))

      expect(Bugsnag).to(have_sent_notification do |payload, _headers|
        event = get_event_from_payload(payload)

        expect(event["metaData"]["important"]).to be_nil
        expect(event["metaData"]["significant"]).to eq({ "hey" => "earth" })
      end)
    end

    it "callbacks are called in FIFO order when added in separate threads" do
      callback1 = proc do |report|
        expect(report.meta_data[:important]).to be_nil

        report.add_tab(:important, { magic_number: 9 })
      end

      callback2 = proc do |report|
        expect(report.meta_data[:important]).to eq({ magic_number: 9 })

        report.add_tab(:important, { magic_number: 99 })
      end

      callback3 = proc do |report|
        expect(report.meta_data[:important]).to eq({ magic_number: 99 })

        report.add_tab(:important, { magic_number: 999 })
      end

      # As above, we need to create & join these one at a time so that each
      # callback is added in sequence
      Thread.new { Bugsnag.add_on_error(callback1) }.join
      Thread.new { Bugsnag.add_on_error(callback2) }.join
      Thread.new { Bugsnag.add_on_error(callback3) }.join

      Bugsnag.notify(RuntimeError.new("Oh no!"))

      expect(Bugsnag).to(have_sent_notification do |payload, _headers|
        event = get_event_from_payload(payload)

        expect(event["metaData"]["important"]).to eq({ "magic_number" => 999 })
      end)
    end
  end
end
