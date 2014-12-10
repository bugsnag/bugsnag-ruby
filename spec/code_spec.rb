require 'spec_helper'

describe Bugsnag::Notification do
  it "includes code in the stack trace" do
    _a = 1
    _b = 2
    _c = 3
    notify_test_exception
    _d = 4
    _e = 5
    _f = 6

    expect(Bugsnag).to have_sent_notification{ |payload|
      exception = get_exception_from_payload(payload)
      starting_line = __LINE__ - 10
      expect(exception["stacktrace"][1]["code"]).to eq({
        (starting_line + 0).to_s => "    _a = 1",
        (starting_line + 1).to_s => "    _b = 2",
        (starting_line + 2).to_s => "    _c = 3",
        (starting_line + 3).to_s => "    notify_test_exception",
        (starting_line + 4).to_s => "    _d = 4",
        (starting_line + 5).to_s => "    _e = 5",
        (starting_line + 6).to_s => "    _f = 6"
        })
    }
  end

  it "allows you to disable sending code" do
    Bugsnag.configuration.send_code = false

    notify_test_exception

    expect(Bugsnag).to have_sent_notification{ |payload|
      exception = get_exception_from_payload(payload)
      expect(exception["stacktrace"][1]["code"]).to eq(nil)
    }
  end

  it 'should send the first 7 lines of the file for exceptions near the top' do
    load 'spec/fixtures/crashes/start_of_file.rb' rescue Bugsnag.notify $!

    expect(Bugsnag).to have_sent_notification{ |payload|
      exception = get_exception_from_payload(payload)

      expect(exception["stacktrace"][0]["code"]).to eq({
        "1" => "#",
        "2" => "raise 'hell'",
        "3" => "#",
        "4" => "#",
        "5" => "#",
        "6" => "#",
        "7" => "#"
      })
    }
  end

  it 'should send the last 7 lines of the file for exceptions near the bottom' do
    load 'spec/fixtures/crashes/end_of_file.rb' rescue Bugsnag.notify $!

    expect(Bugsnag).to have_sent_notification{ |payload|
      exception = get_exception_from_payload(payload)

      expect(exception["stacktrace"][0]["code"]).to eq({
        "3" => "#",
        "4" => "#",
        "5" => "#",
        "6" => "#",
        "7" => "#",
        "8" => "raise 'hell'",
        "9" => "#"
      })
    }
  end

  it 'should send the last 7 lines of the file for exceptions near the bottom' do
    load 'spec/fixtures/crashes/short_file.rb' rescue Bugsnag.notify $!

    expect(Bugsnag).to have_sent_notification{ |payload|
      exception = get_exception_from_payload(payload)

      expect(exception["stacktrace"][0]["code"]).to eq({
        "1" => "raise 'hell'"
      })
    }
  end
end
