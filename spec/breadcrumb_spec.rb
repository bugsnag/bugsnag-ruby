# encoding: utf-8
require 'spec_helper'

describe Bugsnag::Breadcrumbs::Breadcrumb do
    context "when creating a breadcrumb" do

        it "should trim the name if the name is too long" do
            name = "x" * 50
            crumb = Bugsnag::Breadcrumbs::Breadcrumb.new(name)
            expect(crumb.name).to eq("x" * 30)
        end

        it "should default to a MANUAL_TYPE if no type given" do
            crumb = Bugsnag::Breadcrumbs::Breadcrumb.new("Test")
            expect(crumb.type).to eq(Bugsnag::Breadcrumbs::MANUAL_TYPE)
        end

        it "should default to a MANUAL_TYPE if an invalid type is given" do
            crumb = Bugsnag::Breadcrumbs::Breadcrumb.new("Test", "Error")
            expect(crumb.type).to eq(Bugsnag::Breadcrumbs::MANUAL_TYPE)
        end

        it "should assign the name and type specified" do
            breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("Test", Bugsnag::Breadcrumbs::ERROR_TYPE)
            expect(breadcrumb.name).to eq("Test")
            expect(breadcrumb.type).to eq(Bugsnag::Breadcrumbs::ERROR_TYPE)
            expect(breadcrumb.metadata).to eq({})
        end

        it "should create a timestamp" do
            breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("Test", Bugsnag::Breadcrumbs::ERROR_TYPE)
            expect(breadcrumb.timestamp).to be_a_kind_of(String)
        end

        it "should assign the metadata if specified" do
            breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("Test", Bugsnag::Breadcrumbs::ERROR_TYPE, {:foo => "foo", :bar => "bar"})
            expect(breadcrumb.metadata).to include(:foo => "foo")
            expect(breadcrumb.metadata).to include(:bar => "bar")
        end
    end

    context  "when calling as_json" do
        it "should return a hash" do
            breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("Test", Bugsnag::Breadcrumbs::ERROR_TYPE, {:foo => "foo", :bar => "bar"})
            expect(breadcrumb.as_json).to include(:name => "Test")
            expect(breadcrumb.as_json).to include(:type => Bugsnag::Breadcrumbs::ERROR_TYPE)
            expect(breadcrumb.as_json).to include(:timestamp => be_a_kind_of(String))
            expect(breadcrumb.as_json).to include(:metaData => {:foo => "foo", :bar => "bar"})
        end
    end
end