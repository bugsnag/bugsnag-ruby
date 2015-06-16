require 'spec_helper'
require 'bugsnag/faraday'

RSpec.describe Bugsnag::Faraday do
  context "faraday error" do
    subject do
      ::Faraday.new :url => "http://example.com/" do |faraday|
        faraday.use :bugsnag
        faraday.response :raise_error
        faraday.adapter :test do |stub|
          stub.get('/') { |env| [500, {}, 'foo'] }
        end
      end
    end
    it "adds bugsnag meta data" do
      expect {
        subject.get("/")
      }.to raise_error { |e|
        expect(e).to respond_to(:bugsnag_meta_data)
        expect(e.bugsnag_meta_data).not_to be_nil
      }
    end
  end
  context "faraday error" do
    subject do
      ::Faraday.new :url => "http://example.com/" do |faraday|
        faraday.use :bugsnag
        faraday.response :raise_error
        faraday.adapter :test do |stub|
          stub.get('/') { |env| raise "foo" }
        end
      end
    end
    it "does not add bugsnag meta data" do
      expect {
        subject.get("/")
      }.to raise_error { |e|
        expect(e).not_to respond_to(:bugsnag_meta_data)
      }
    end
  end
end
