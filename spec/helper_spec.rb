# encoding: utf-8

require 'spec_helper'
require 'set'

describe Bugsnag::Helpers do
  describe "trim_if_needed" do
    it "preserves bool types" do
      value = Bugsnag::Helpers.trim_if_needed([1, 3, true, "NO", "2", false])
      expect(value[2]).to be_a(TrueClass)
      expect(value[5]).to be_a(FalseClass)
    end

    it "preserves Numeric types" do
      value = Bugsnag::Helpers.trim_if_needed([1, 3.445, true, "NO", "2", false])
      expect(value[0]).to be_a(Numeric)
      expect(value[1]).to be_a(Numeric)
    end

    it "preserves String types" do
      value = Bugsnag::Helpers.trim_if_needed([1, 3, true, "NO", "2", false])
      expect(value[3]).to be_a(String)
      expect(value[4]).to be_a(String)
    end

    context "payload length is less than allowed" do
      it "does not change strings" do
        value = SecureRandom.hex(4096)
        expect(Bugsnag::Helpers.trim_if_needed(value)).to eq value
      end

      it "does not change arrays" do
        value = 1000.times.map {|i| "#{i} - #{i + 1}" }
        expect(Bugsnag::Helpers.trim_if_needed(value)).to eq value
      end

      it "does not change hashes" do
        value = Hash[*1000.times.map{|i| ["#{i}", i]}.flatten]
        expect(Bugsnag::Helpers.trim_if_needed(value)).to eq value
      end
    end

    context "payload length is greater than allowed" do
      it "trims exception messages" do
        payload = {
          :events => [{
            :exceptions => [{
              :message => 50000.times.map {|i| "should truncate" }.join(""),
              :preserved => "Foo"
            }]
          }]
        }
        expect(::JSON.dump(payload).length).to be > Bugsnag::Helpers::MAX_PAYLOAD_LENGTH
        trimmed = Bugsnag::Helpers.trim_if_needed(payload)
        expect(::JSON.dump(trimmed).length).to be <= Bugsnag::Helpers::MAX_PAYLOAD_LENGTH
        expect(trimmed[:events][0][:exceptions][0][:message].length).to be <= Bugsnag::Helpers::MAX_STRING_LENGTH
        expect(trimmed[:events][0][:exceptions][0][:preserved]).to eq("Foo")
      end

      it "trims metadata strings" do
        payload = {
          :events => [{
            :exceptions => [],
            :metaData => 50000.times.map {|i| "should truncate" }.join(""),
            :preserved => "Foo"
          }]
        }
        expect(::JSON.dump(payload).length).to be > Bugsnag::Helpers::MAX_PAYLOAD_LENGTH
        trimmed = Bugsnag::Helpers.trim_if_needed(payload)
        expect(::JSON.dump(trimmed).length).to be <= Bugsnag::Helpers::MAX_PAYLOAD_LENGTH
        expect(trimmed[:events][0][:metaData].length).to be <= Bugsnag::Helpers::MAX_STRING_LENGTH
        expect(trimmed[:events][0][:preserved]).to eq("Foo")
      end

      it "truncates metadata arrays" do
        payload = {
          :events => [{
            :exceptions => [],
            :metaData => 50000.times.map {|i| "should truncate" },
            :preserved => "Foo"
          }]
        }
        expect(::JSON.dump(payload).length).to be > Bugsnag::Helpers::MAX_PAYLOAD_LENGTH
        trimmed = Bugsnag::Helpers.trim_if_needed(payload)
        expect(::JSON.dump(trimmed).length).to be <= Bugsnag::Helpers::MAX_PAYLOAD_LENGTH
        expect(trimmed[:events][0][:metaData].length).to be <= Bugsnag::Helpers::MAX_ARRAY_LENGTH
        expect(trimmed[:events][0][:preserved]).to eq("Foo")
      end

      it "trims stacktrace code" do
        payload = {
          :events => [{
            :exceptions => [{
              :stacktrace => [
                {
                  :lineNumber => 1,
                  :file => '/trace1',
                  :code => 50.times.map {|i| SecureRandom.hex(3072) }
                },
                {
                  :lineNumber => 2,
                  :file => '/trace2',
                  :code => 50.times.map {|i| SecureRandom.hex(3072) }
                }
              ]
            }]
          }]
        }
        expect(::JSON.dump(payload).length).to be > Bugsnag::Helpers::MAX_PAYLOAD_LENGTH
        trimmed = Bugsnag::Helpers.trim_if_needed(payload)
        expect(::JSON.dump(trimmed).length).to be <= Bugsnag::Helpers::MAX_PAYLOAD_LENGTH
        trace = trimmed[:events][0][:exceptions][0][:stacktrace]
        expect(trace.length).to eq(2)
        expect(trace[0][:lineNumber]).to eq(1)
        expect(trace[0][:file]).to eq('/trace1')
        expect(trace[0][:code]).to be_nil
        expect(trace[1][:lineNumber]).to eq(2)
        expect(trace[1][:file]).to eq('/trace2')
        expect(trace[1][:code]).to be_nil
      end

      it "trims stacktrace entries" do
        payload = {
          :events => [{
            :exceptions => [{
              :stacktrace => 18000.times.map do |index|
                {
                  :lineNumber => index,
                  :file => "/path/to/item_#{index}.rb",
                  :code => { "#{index}" => "puts 'code'" }
                }
              end
            }]
          }]
        }
        expect(::JSON.dump(payload).length).to be > Bugsnag::Helpers::MAX_PAYLOAD_LENGTH
        trimmed = Bugsnag::Helpers.trim_if_needed(payload)
        expect(::JSON.dump(trimmed).length).to be <= Bugsnag::Helpers::MAX_PAYLOAD_LENGTH
        trace = trimmed[:events][0][:exceptions][0][:stacktrace]
        expect(trace.length).to eq(30)
        30.times.map do |index|
          expect(trace[index][:lineNumber]).to eq(index)
          expect(trace[index][:file]).to eq("/path/to/item_#{index}.rb")
          expect(trace[index][:code]).to be_nil
        end
      end
    end
  end
end
