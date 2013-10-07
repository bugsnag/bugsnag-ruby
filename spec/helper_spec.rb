require 'spec_helper'

describe Bugsnag::Helpers do
  it "should be able to clean up recursive hashes" do
    a = {:a => {}}
    a[:a][:b] = a
    Bugsnag::Helpers.cleanup_obj(a).should == {:a => {:b => "[RECURSION]"}}
  end

  it "should be able to clean up recursive arrays" do
    a = []
    a << a
    a << "hello"
    Bugsnag::Helpers.cleanup_obj(a).should == ["[RECURSION]", "hello"]
  end

  it "should allow multiple copies of the same string" do
    a = {:name => "bugsnag"}
    a[:second] = a[:name]
    Bugsnag::Helpers.cleanup_obj(a).should == {:name => "bugsnag", :second => "bugsnag"}
  end

  it "should allow multiple copies of the same object" do
    a = []
    b = ["hello"]
    a << b; a << b
    Bugsnag::Helpers.cleanup_obj(a).should == [["hello"], ["hello"]]
  end

  it "should reduce hash size correctly" do
    meta_data = {
      :key_one => "this should not be truncated",
      :key_two => ""
    }

    1000.times {|i| meta_data[:key_two] += "this should be truncated " }

    meta_data[:key_two].length.should > 4096

    meta_data_return = Bugsnag::Helpers.reduce_hash_size meta_data

    meta_data_return[:key_one].length.should == 28
    meta_data_return[:key_one].should == "this should not be truncated"

    meta_data_return[:key_two].length.should == 4107
    meta_data_return[:key_two].match(/\[TRUNCATED\]$/).nil?.should == false

    meta_data[:key_two].length.should > 4096
    meta_data[:key_two].match(/\[TRUNCATED\]$/).nil?.should == true

    meta_data[:key_one].length.should == 28
    meta_data[:key_one].should == "this should not be truncated"
  end

  it "should work with no filters configured" do
    url = Bugsnag::Helpers.cleanup_url "/dir/page?param1=value1&param2=value2"

    url.should == "/dir/page?param1=value1&param2=value2"
  end

  it "should not filter with no get params" do
    url = Bugsnag::Helpers.cleanup_url "/dir/page"

    url.should == "/dir/page"
  end

  it "should leave a url alone if no filters match" do
    url = Bugsnag::Helpers.cleanup_url "/dir/page?param1=value1&param2=value2", ["param3"]

    url.should == "/dir/page?param1=value1&param2=value2"
  end

  it "should filter a single get param" do
    url = Bugsnag::Helpers.cleanup_url "/dir/page?param1=value1&param2=value2", ["param1"]

    url.should == "/dir/page?param1=[FILTERED]&param2=value2"
  end

  it "should filter a get param that contains a filtered term" do
    url = Bugsnag::Helpers.cleanup_url '/dir/page?param1=value1&param2=value2&bla=yes', ["param"]

    url.should == "/dir/page?param1=[FILTERED]&param2=[FILTERED]&bla=yes"
  end

  it "should filter multiple matches" do
    url = Bugsnag::Helpers.cleanup_url "/dir/page?param1=value1&param2=value2&param3=value3", ["param1", "param2"]

    url.should == "/dir/page?param1=[FILTERED]&param2=[FILTERED]&param3=value3"
  end
end
