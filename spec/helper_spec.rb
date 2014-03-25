require 'spec_helper'

describe Bugsnag::Helpers do
  it "cleans up recursive hashes" do
    a = {:a => {}}
    a[:a][:b] = a
    expect(Bugsnag::Helpers.cleanup_obj(a)).to eq({:a => {:b => "[RECURSION]"}})
  end

  it "cleans up recursive arrays" do
    a = []
    a << a
    a << "hello"
    expect(Bugsnag::Helpers.cleanup_obj(a)).to eq(["[RECURSION]", "hello"])
  end

  it "allows multiple copies of the same string" do
    a = {:name => "bugsnag"}
    a[:second] = a[:name]
    expect(Bugsnag::Helpers.cleanup_obj(a)).to eq({:name => "bugsnag", :second => "bugsnag"})
  end

  it "allows multiple copies of the same object" do
    a = []
    b = ["hello"]
    a << b; a << b
    expect(Bugsnag::Helpers.cleanup_obj(a)).to eq([["hello"], ["hello"]])
  end

  it "reduces hash size correctly" do
    meta_data = {
      :key_one => "this should not be truncated",
      :key_two => ""
    }

    1000.times {|i| meta_data[:key_two] += "this should be truncated " }

    expect(meta_data[:key_two].length).to be > 4096

    meta_data_return = Bugsnag::Helpers.reduce_hash_size meta_data

    expect(meta_data_return[:key_one].length).to eq(28)
    expect(meta_data_return[:key_one]).to eq("this should not be truncated")

    expect(meta_data_return[:key_two].length).to eq(4107)
    expect(meta_data_return[:key_two].match(/\[TRUNCATED\]$/).nil?).to eq(false)

    expect(meta_data[:key_two].length).to be > 4096
    expect(meta_data[:key_two].match(/\[TRUNCATED\]$/).nil?).to eq(true)

    expect(meta_data[:key_one].length).to eq(28)
    expect(meta_data[:key_one]).to eq("this should not be truncated")
  end

  it "works with no filters configured" do
    url = Bugsnag::Helpers.cleanup_url "/dir/page?param1=value1&param2=value2"

    expect(url).to eq("/dir/page?param1=value1&param2=value2")
  end

  it "does not filter with no get params" do
    url = Bugsnag::Helpers.cleanup_url "/dir/page"

    expect(url).to eq("/dir/page")
  end

  it "leaves a url alone if no filters match" do
    url = Bugsnag::Helpers.cleanup_url "/dir/page?param1=value1&param2=value2", ["param3"]

    expect(url).to eq("/dir/page?param1=value1&param2=value2")
  end

  it "filters a single get param" do
    url = Bugsnag::Helpers.cleanup_url "/dir/page?param1=value1&param2=value2", ["param1"]

    expect(url).to eq("/dir/page?param1=[FILTERED]&param2=value2")
  end

  it "filters a get param that contains a filtered term" do
    url = Bugsnag::Helpers.cleanup_url '/dir/page?param1=value1&param2=value2&bla=yes', ["param"]

    expect(url).to eq("/dir/page?param1=[FILTERED]&param2=[FILTERED]&bla=yes")
  end

  it "filters multiple matches" do
    url = Bugsnag::Helpers.cleanup_url "/dir/page?param1=value1&param2=value2&param3=value3", ["param1", "param2"]

    expect(url).to eq("/dir/page?param1=[FILTERED]&param2=[FILTERED]&param3=value3")
  end
end
