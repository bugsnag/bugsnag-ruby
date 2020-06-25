require 'spec_helper'

describe Bugsnag::Stacktrace do
  context "sending code" do
    it "includes code in the stack trace" do
      begin
        _a = 1
        _b = 2
        _c = 3
        "Test".prepnd "T"
        _d = 4
        _e = 5
        _f = 6
      rescue Exception => e
        Bugsnag.notify(e)
      end

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        exception = get_exception_from_payload(payload)
        starting_line = __LINE__ - 13
        expect(exception["stacktrace"][0]["code"]).to eq({
          (starting_line + 0).to_s => '        _a = 1',
          (starting_line + 1).to_s => '        _b = 2',
          (starting_line + 2).to_s => '        _c = 3',
          (starting_line + 3).to_s => '        "Test".prepnd "T"',
          (starting_line + 4).to_s => '        _d = 4',
          (starting_line + 5).to_s => '        _e = 5',
          (starting_line + 6).to_s => '        _f = 6'
          })
      }
    end

    it "allows you to disable sending code" do
      Bugsnag.configuration.send_code = false

      notify_test_exception

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        exception = get_exception_from_payload(payload)
        expect(exception["stacktrace"][1]["code"]).to eq(nil)
      }
    end

    it 'should send the first 7 lines of the file for exceptions near the top' do
      load 'spec/fixtures/crashes/start_of_file.rb' rescue Bugsnag.notify $!

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
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

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
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

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        exception = get_exception_from_payload(payload)

        expect(exception["stacktrace"][0]["code"]).to eq({
          "1" => "raise 'hell'"
        })
      }
    end
  end

  context "file paths" do
    it "leaves absolute paths alone" do
      configuration = Bugsnag::Configuration.new
      configuration.send_code = false

      dir = File.dirname(__FILE__)

      backtrace = [
        "/foo/bar/app/models/user.rb:1:in `something'",
        "/foo/bar/other_vendor/lib/dont.rb:2:in `to_s'",
        "/foo/bar/vendor/lib/ignore_me.rb:3:in `to_s'",
        "/foo/bar/.bundle/lib/ignore_me.rb:4:in `to_s'",
        "#{dir}/../spec/stacktrace_spec.rb:5:in `something_else'",
      ]

      stacktrace = Bugsnag::Stacktrace.new(backtrace, configuration).to_a

      expect(stacktrace).to eq([
        { file: "/foo/bar/app/models/user.rb", lineNumber: 1, method: "something" },
        { file: "/foo/bar/other_vendor/lib/dont.rb", lineNumber: 2, method: "to_s" },
        { file: "/foo/bar/vendor/lib/ignore_me.rb", lineNumber: 3, method: "to_s" },
        { file: "/foo/bar/.bundle/lib/ignore_me.rb", lineNumber: 4, method: "to_s" },
        { file: "#{dir}/../spec/stacktrace_spec.rb", lineNumber: 5, method: "something_else" },
      ])
    end

    it "does not modify relative paths if they can't be resolved" do
      configuration = Bugsnag::Configuration.new

      backtrace = [
        "./foo/bar/baz.rb:1:in `something'",
        "../foo.rb:1:in `to_s'",
        "../xyz.rb:1:in `to_s'",
        "abc.rb:1:in `defg'",
      ]

      stacktrace = Bugsnag::Stacktrace.new(backtrace, configuration).to_a

      expect(stacktrace).to eq([
        { code: nil, file: "./foo/bar/baz.rb", lineNumber: 1, method: "something" },
        { code: nil, file: "../foo.rb", lineNumber: 1, method: "to_s" },
        { code: nil, file: "../xyz.rb", lineNumber: 1, method: "to_s" },
        { code: nil, file: "abc.rb", lineNumber: 1, method: "defg" },
      ])
    end

    it "resolves relative paths when the files exist" do
      configuration = Bugsnag::Configuration.new
      configuration.send_code = false

      backtrace = [
        "./spec/spec_helper.rb:1:in `something'",
        "./lib/bugsnag/breadcrumbs/../configuration.rb:100:in `to_s'",
        "lib/bugsnag.rb:20:in `notify'",
      ]

      stacktrace = Bugsnag::Stacktrace.new(backtrace, configuration).to_a

      dir = File.dirname(__FILE__)

      expect(stacktrace).to eq([
        { file: "#{dir}/spec_helper.rb", lineNumber: 1, method: "something" },
        { file: "#{File.dirname(dir)}/lib/bugsnag/configuration.rb", lineNumber: 100, method: "to_s" },
        { file: "#{File.dirname(dir)}/lib/bugsnag.rb", lineNumber: 20, method: "notify" },
      ])
    end
  end

  context "with configurable vendor_path" do
    let(:configuration) do
      configuration = Bugsnag::Configuration.new
      configuration.project_root = "/foo/bar"
      configuration
    end

    let(:backtrace) do
      [
        "/foo/bar/app/models/user.rb:1:in `something'",
        "/foo/bar/other_vendor/lib/dont.rb:1:in `to_s'",
        "/foo/bar/vendor/lib/ignore_me.rb:1:in `to_s'",
        "/foo/bar/.bundle/lib/ignore_me.rb:1:in `to_s'",
      ]
    end

    def out_project_trace(stacktrace)
      stacktrace.to_a.map do |trace_line|
        trace_line[:file] if !trace_line[:inProject]
      end.compact
    end

    it "marks vendor/ and .bundle/ as out-project by default" do
      stacktrace = Bugsnag::Stacktrace.new(backtrace, configuration)

      expect(out_project_trace(stacktrace)).to eq([
        "vendor/lib/ignore_me.rb",
        ".bundle/lib/ignore_me.rb",
      ])
    end

    it "allows vendor_path to be configured and filters out backtrace file paths" do
      configuration.vendor_path = /other_vendor\//
      stacktrace = Bugsnag::Stacktrace.new(backtrace, configuration)

      expect(out_project_trace(stacktrace)).to eq(["other_vendor/lib/dont.rb"])
    end
  end
end
