# encoding: utf-8

require 'spec_helper'

describe Bugsnag::Helpers do
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
end
