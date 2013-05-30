require 'spec_helper'

describe Bugsnag::Helpers do
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