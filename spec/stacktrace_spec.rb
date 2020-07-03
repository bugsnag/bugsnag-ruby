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

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        starting_line = __LINE__ - 12

        expect(get_code_from_payload(payload).to_a).to eq({
          (starting_line + 0).to_s => '        _a = 1',
          (starting_line + 1).to_s => '        _b = 2',
          (starting_line + 2).to_s => '        _c = 3',
          (starting_line + 3).to_s => '        "Test".prepnd "T"',
          (starting_line + 4).to_s => '        _d = 4',
          (starting_line + 5).to_s => '        _e = 5',
          (starting_line + 6).to_s => '        _f = 6'
        }.to_a)
      }
    end

    it "allows you to disable sending code" do
      Bugsnag.configuration.send_code = false

      notify_test_exception

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        expect(get_code_from_payload(payload)).to eq(nil)
      }
    end

    it 'should send the first 7 lines of the file for exceptions near the top' do
      load 'spec/fixtures/crashes/start_of_file.rb' rescue Bugsnag.notify $!

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        expect(get_code_from_payload(payload).to_a).to eq({
          "1" => "#",
          "2" => "raise 'hell'",
          "3" => "#",
          "4" => "#",
          "5" => "#",
          "6" => "#",
          "7" => "#"
        }.to_a)
      }
    end

    it 'should send the last 7 lines of the file for exceptions near the bottom' do
      load 'spec/fixtures/crashes/end_of_file.rb' rescue Bugsnag.notify $!

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        expect(get_code_from_payload(payload)).to eq({
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

    it 'should send every line of a very short file' do
      load 'spec/fixtures/crashes/short_file.rb' rescue Bugsnag.notify $!

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        expect(get_code_from_payload(payload).to_a).to eq({
          "1" => "#",
          "2" => "raise 'hell'",
          "3" => "#"
        }.to_a)
      }
    end

    it 'should send code for each line in the stacktrace' do
      load 'spec/fixtures/crashes/functions.rb' rescue Bugsnag.notify $!

      expected_code = [
        # The topmost frame is centered on where the exception was raised
        {
          "11" => "end",
          "12" => "",
          "13" => "def xyz",
          "14" => "  raise 'uh oh'",
          "15" => "end",
          "16" => "",
          "17" => "def abc"
        },
        # then we get 'baz' which is where 'xyz' was called
        {
          "7" => "end",
          "8" => "",
          "9" => "def baz",
          "10" => "  xyz",
          "11" => "end",
          "12" => "",
          "13" => "def xyz"
        },
        # then we get 'bar' which is where 'baz' was called
        {
          "3" => "end",
          "4" => "",
          "5" => "def bar",
          "6" => "  baz",
          "7" => "end",
          "8" => "",
          "9" => "def baz"
        },
        # then we get 'foo' which is where 'bar' was called - this is the first
        # 7 lines because the call to 'bar' is on line 2
        {
          "1" => "def foo",
          "2" => "  bar",
          "3" => "end",
          "4" => "",
          "5" => "def bar",
          "6" => "  baz",
          "7" => "end"
        },
        # finally we get the call to 'foo' - this is the last 7 lines because
        # the call is on the last line of the file
        {
          "23" => "end",
          "24" => "",
          "25" => "def abcdefghi",
          "26" => "  puts 'abcdefghi'",
          "27" => "end",
          "28" => "",
          "29" => "foo"
        }
      ]

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        (0...expected_code.size).each do |index|
          expect(get_code_from_payload(payload, index).to_a).to eq(expected_code[index].to_a)
        end
      }
    end

    it 'should send code for each line in the stacktrace when split over multiple files' do
      load 'spec/fixtures/crashes/file1.rb' rescue Bugsnag.notify $!

      expected_code = [
        {
          "8" => "  end",
          "9" => "",
          "10" => "  def self.baz2",
          "11" => "    raise 'uh oh'",
          "12" => "  end",
          "13" => "",
          "14" => "  def self.abc2"
        },
        {
          "10" => "  end",
          "11" => "",
          "12" => "  def self.baz1",
          "13" => "    File2.baz2",
          "14" => "  end",
          "15" => "",
          "16" => "  def self.abc1"
        },
        {
          "4" => "  end",
          "5" => "",
          "6" => "  def self.bar2",
          "7" => "    File1.baz1",
          "8" => "  end",
          "9" => "",
          "10" => "  def self.baz2"
        },
        {
          "6" => "  end",
          "7" => "",
          "8" => "  def self.bar1",
          "9" => "    File2.bar2",
          "10" => "  end",
          "11" => "",
          "12" => "  def self.baz1",
        },
        {
          "1" => "module File2",
          "2" => "  def self.foo2",
          "3" => "    File1.bar1",
          "4" => "  end",
          "5" => "",
          "6" => "  def self.bar2",
          "7" => "    File1.baz1"
        },
        {
          "2" => "",
          "3" => "module File1",
          "4" => "  def self.foo1",
          "5" => "    File2.foo2",
          "6" => "  end",
          "7" => "",
          "8" => "  def self.bar1"
        },
        {
          "23" => "",
          "24" => "  def self.abcdefghi1",
          "25" => "    puts 'abcdefghi1'",
          "26" => "  end",
          "27" => "end",
          "28" => "",
          "29" => "File1.foo1"
        }
      ]

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        (0...expected_code.size).each do |index|
          expect(get_code_from_payload(payload, index).to_a).to eq(expected_code[index].to_a)
        end
      }
    end
  end

  context "file paths" do
    it "leaves absolute paths alone" do
      configuration = Bugsnag::Configuration.new
      configuration.send_code = false

      backtrace = [
        "/foo/bar/app/models/user.rb:1:in `something'",
        "/foo/bar/other_vendor/lib/dont.rb:2:in `to_s'",
        "/foo/bar/vendor/lib/ignore_me.rb:3:in `to_s'",
        "/foo/bar/.bundle/lib/ignore_me.rb:4:in `to_s'",
      ]

      stacktrace = Bugsnag::Stacktrace.process(backtrace, configuration).to_a

      expect(stacktrace).to eq([
        { file: "/foo/bar/app/models/user.rb", lineNumber: 1, method: "something" },
        { file: "/foo/bar/other_vendor/lib/dont.rb", lineNumber: 2, method: "to_s" },
        { file: "/foo/bar/vendor/lib/ignore_me.rb", lineNumber: 3, method: "to_s" },
        { file: "/foo/bar/.bundle/lib/ignore_me.rb", lineNumber: 4, method: "to_s" },
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

      stacktrace = Bugsnag::Stacktrace.process(backtrace, configuration).to_a

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

      dir = File.dirname(__FILE__)

      backtrace = [
        "./spec/spec_helper.rb:1:in `something'",
        "./lib/bugsnag/breadcrumbs/../configuration.rb:100:in `to_s'",
        "lib/bugsnag.rb:20:in `notify'",
        "#{dir}/../spec/stacktrace_spec.rb:5:in `something_else'",
      ]

      stacktrace = Bugsnag::Stacktrace.process(backtrace, configuration).to_a

      expect(stacktrace).to eq([
        { file: "#{dir}/spec_helper.rb", lineNumber: 1, method: "something" },
        { file: "#{File.dirname(dir)}/lib/bugsnag/configuration.rb", lineNumber: 100, method: "to_s" },
        { file: "#{File.dirname(dir)}/lib/bugsnag.rb", lineNumber: 20, method: "notify" },
        { file: "#{dir}/stacktrace_spec.rb", lineNumber: 5, method: "something_else" },
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
      stacktrace.map do |trace_line|
        trace_line[:file] unless trace_line[:inProject]
      end.compact
    end

    it "marks vendor/ and .bundle/ as out-project by default" do
      stacktrace = Bugsnag::Stacktrace.process(backtrace, configuration)

      expect(out_project_trace(stacktrace)).to eq([
        "vendor/lib/ignore_me.rb",
        ".bundle/lib/ignore_me.rb",
      ])
    end

    it "allows vendor_path to be configured and filters out backtrace file paths" do
      configuration.vendor_path = /other_vendor\//
      stacktrace = Bugsnag::Stacktrace.process(backtrace, configuration)

      expect(out_project_trace(stacktrace)).to eq(["other_vendor/lib/dont.rb"])
    end
  end
end
