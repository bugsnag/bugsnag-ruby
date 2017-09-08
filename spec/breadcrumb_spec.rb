# encoding: utf-8
require 'spec_helper'

describe Bugsnag::Breadcrumbs::Breadcrumb do
    context "when creating a breadcrumb" do
        it "should throw an ArgumentError if no name is given" do
            begin
                Bugsnag::Breadcrumbs::Breadcrumb.new
            rescue => exception
                expect(exception).to be_a_kind_of(ArgumentError)
            end
        end

        it "should throw an ArgumentError if the name is an empty string" do
            begin
                Bugsnag::Breadcrumbs::Breadcrumb.new("", nil)
            rescue => exception
                expect(exception).to be_a_kind_of(ArgumentError)
            end
        end

        it "should throw an ArgumentError if the name is too long" do
            begin
                name = "x" * 50
                Bugsnag::Breadcrumbs::Breadcrumb.new(name, nil)
            rescue => exception
                expect(exception).to be_a_kind_of(ArgumentError)
            end
        end

        it "should throw an ArgumentError if no type given" do
            begin
                Bugsnag::Breadcrumbs::Breadcrumb.new("Test", nil)
            rescue => exception
                expect(exception).to be_a_kind_of(ArgumentError)
            end       
        end

        it "should throw an ArgumentError if an invalid type is given" do
            begin
                Bugsnag::Breadcrumbs::Breadcrumb.new("Test", "Error")
            rescue => exception
                expect(exception).to be_a_kind_of(ArgumentError)
            end
        end

        it "should assign the name and type specified" do
            breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("Test", Bugsnag::Breadcrumbs::MANUAL_TYPE)
            expect(breadcrumb.name).to eq("Test")
            expect(breadcrumb.type).to eq(Bugsnag::Breadcrumbs::MANUAL_TYPE)
            expect(breadcrumb.metadata).to eq({})
        end

        it "should create a timestamp" do
            breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("Test", Bugsnag::Breadcrumbs::MANUAL_TYPE)
            expect(breadcrumb.timestamp).to be_a_kind_of(String)
        end

        it "should assign the metadata if specified" do
            breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("Test", Bugsnag::Breadcrumbs::MANUAL_TYPE, {:foo => "foo", :bar => "bar"})
            expect(breadcrumb.metadata).to include(:foo => "foo")
            expect(breadcrumb.metadata).to include(:bar => "bar")
        end
    end

    context  "when calling as_hash" do
        it "should return a hash" do
            breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("Test", Bugsnag::Breadcrumbs::MANUAL_TYPE, {:foo => "foo", :bar => "bar"})
            expect(breadcrumb.as_hash).to be_a_kind_of(Hash)
            expect(breadcrumb.as_hash).to include(:name => "Test")
            expect(breadcrumb.as_hash).to include(:type => Bugsnag::Breadcrumbs::MANUAL_TYPE)
            expect(breadcrumb.as_hash).to include(:timestamp => be_a_kind_of(String))
            expect(breadcrumb.as_hash).to_not include(:metadata)
        end
    end
end