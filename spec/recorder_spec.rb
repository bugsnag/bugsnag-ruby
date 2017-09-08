# encoding: utf-8
require 'spec_helper'

describe Bugsnag::Breadcrumbs::Recorder do

    context "when creating" do
        it "does not initialize any breadcrumbs" do
            recorder = Bugsnag::Breadcrumbs::Recorder.new
            expect(recorder.breadcrumbs).to be_a_kind_of(Array)
            expect(recorder.breadcrumbs.length).to eq(0)
        end

        it "intializes counter at 0" do
            recorder = Bugsnag::Breadcrumbs::Recorder.new
            expect(recorder.current_item).to eq(0)
        end
    end

    context "when adding breadcrumbs" do
        before do
            @recorder = Bugsnag::Breadcrumbs::Recorder.new
        end

        it "stores the breadcrumb" do
            @recorder.add_breadcrumb "Test"
            expect(@recorder.breadcrumbs.length).to eq(1)
            expect(@recorder.breadcrumbs).to include("Test")
        end

        it "increments the counter" do
            @recorder.add_breadcrumb 0
            expect(@recorder.current_item).to eq(1)

            @recorder.add_breadcrumb 1
            expect(@recorder.current_item).to eq(2)
        end

        it "does not store more than MAX_ITEMS breadcrumbs" do
            max_items = Bugsnag::Breadcrumbs::Recorder::MAX_ITEMS
            [*1..(max_items + 10)].each do |crumb|
                @recorder.add_breadcrumb crumb
            end
            expect(@recorder.breadcrumbs.length).to be <= max_items
        end

        it "wraps the breadcrumbs" do
            max_items = Bugsnag::Breadcrumbs::Recorder::MAX_ITEMS
            [*1..(max_items + 10)].each do |crumb|
                @recorder.add_breadcrumb crumb
            end
            [*11..(max_items + 10)].each do |val|
                expect(@recorder.breadcrumbs).to include(val)
            end
            [*1..10].each do |val|
                expect(@recorder.breadcrumbs).to_not include(val)
            end
        end
    end

    context "when retrieving the breadcrumbs" do
        before do
            @recorder = Bugsnag::Breadcrumbs::Recorder.new
        end

        it "throws an error if no block_given" do
            begin
                @recorder.get_breadcrumbs
            rescue => exception
                expect(exception).to be_a_kind_of(ArgumentError)
            end
        end

        it "yields breadcrumbs in order" do
            input = [*1..10]
            input.each do |crumb|
                @recorder.add_breadcrumb crumb
            end
            output = []
            @recorder.get_breadcrumbs do |crumb|
                output.push(crumb)
            end
            expect(output).to eq(input)
        end

        it "yields breadcrumbs in order of addition when wrapped" do
            max_items = Bugsnag::Breadcrumbs::Recorder::MAX_ITEMS
            [*1..(max_items + 10)].each do |crumb|
                @recorder.add_breadcrumb crumb
            end
            output = []
            @recorder.get_breadcrumbs do |crumb|
                output.push(crumb)
            end
            expect(output).to eq([*11..(max_items + 10)])
        end
    end
end