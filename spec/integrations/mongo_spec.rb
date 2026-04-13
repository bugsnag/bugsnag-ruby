# encoding: utf-8
require 'spec_helper'

describe 'Bugsnag::MongoBreadcrumbSubscriber', :order => :defined do
  before do
    unless defined?(::Mongo)
      @mocked_mongo = true
      module ::Mongo
        module Monitoring
          COMMAND = 'Command'
          module Global
          end
        end
      end
      module Kernel
        alias_method :old_require, :require
        def require(path)
          old_require(path) unless path == 'mongo'
        end
      end
    end
  end

  it "should subscribe to the mongo monitoring service" do
    expect(::Mongo::Monitoring::Global).to receive(:subscribe) do |command, subscriber|
      expect(command).to eq(::Mongo::Monitoring::COMMAND)
      expect(subscriber).to be_an_instance_of(::Bugsnag::MongoBreadcrumbSubscriber)
    end
    load './lib/bugsnag/integrations/mongo.rb'
  end

  context "with the module loaded" do
    before do
      allow(::Mongo::Monitoring::Global).to receive(:subscribe)
      require './lib/bugsnag/integrations/mongo'
    end

    let(:subscriber) { Bugsnag::MongoBreadcrumbSubscriber.new }

    describe "#started" do
      it "calls #leave_command with the event" do
        event = double
        expect(subscriber).to receive(:leave_command).with(event)
        subscriber.started(event)
      end
    end

    describe "#succeeded" do
      it "calls #leave_mongo_breadcrumb with the event_name and event" do
        event = double
        expect(subscriber).to receive(:leave_mongo_breadcrumb).with("succeeded", event)
        subscriber.succeeded(event)
      end
    end

    describe "#failed" do
      it "calls #leave_mongo_breadcrumb with the event_name and event" do
        event = double
        expect(subscriber).to receive(:leave_mongo_breadcrumb).with("failed", event)
        subscriber.failed(event)
      end
    end

    describe "#leave_mongo_breadcrumb" do
      let(:event) { double(
        :command_name => "command",
        :database_name => "database",
        :operation_id => "1234567890",
        :request_id => "123456",
        :duration => "123.456"
      ) }
      let(:event_name) { "event_name" }
      it "leaves a breadcrumb with relevant meta_data, message, type, and automatic notation" do
        expect(Bugsnag).to receive(:leave_breadcrumb).with(
          "Mongo query #{event_name}",
          {
            :event_name => "mongo.#{event_name}",
            :command_name => "command",
            :database_name => "database",
            :operation_id => "1234567890",
            :request_id => "123456",
            :duration => "123.456"
          },
          "process",
          :auto
        )
        subscriber.send(:leave_mongo_breadcrumb, event_name, event)
      end

      it "adds message data if present" do
        allow(event).to receive(:message).and_return("This is a message")
        expect(Bugsnag).to receive(:leave_breadcrumb).with(
          "Mongo query #{event_name}",
          {
            :event_name => "mongo.#{event_name}",
            :command_name => "command",
            :database_name => "database",
            :operation_id => "1234567890",
            :request_id => "123456",
            :duration => "123.456",
            :message => "This is a message"
          },
          "process",
          :auto
        )
        subscriber.send(:leave_mongo_breadcrumb, event_name, event)
      end

      context "command data is present" do
        let(:command) {
          {
            "command" => "collection_name_command",
            "collection" => "collection_name_getMore",
            "filter" => nil
          }
        }

        it "adds the collection name" do
          expect(subscriber).to receive(:pop_command).with("123456").and_return(command)
          expect(Bugsnag).to receive(:leave_breadcrumb).with(
            "Mongo query #{event_name}",
            {
              :event_name => "mongo.#{event_name}",
              :command_name => "command",
              :database_name => "database",
              :operation_id => "1234567890",
              :request_id => "123456",
              :duration => "123.456",
              :collection => "collection_name_command"
            },
            "process",
            :auto
          )
          subscriber.send(:leave_mongo_breadcrumb, event_name, event)
        end

        it "adds the correct collection name for 'getMore' commands" do
          allow(event).to receive(:command_name).and_return("getMore")
          expect(subscriber).to receive(:pop_command).with("123456").and_return(command)
          expect(Bugsnag).to receive(:leave_breadcrumb).with(
            "Mongo query #{event_name}",
            {
              :event_name => "mongo.#{event_name}",
              :command_name => "getMore",
              :database_name => "database",
              :operation_id => "1234567890",
              :request_id => "123456",
              :duration => "123.456",
              :collection => "collection_name_getMore"
            },
            "process",
            :auto
          )
          subscriber.send(:leave_mongo_breadcrumb, event_name, event)
        end

        it "adds a JSON string of filter data" do
          command["filter"] = {"a" => 1, "b" => 2, "$or" => [{"c" => 3}, {"d" => 4}]}
          expect(subscriber).to receive(:pop_command).with("123456").and_return(command)
          expect(Bugsnag).to receive(:leave_breadcrumb).with(
            "Mongo query #{event_name}",
            {
              :event_name => "mongo.#{event_name}",
              :command_name => "command",
              :database_name => "database",
              :operation_id => "1234567890",
              :request_id => "123456",
              :duration => "123.456",
              :collection => "collection_name_command",
              :filter => '{"a":"?","b":"?","$or":[{"c":"?"},{"d":"?"}]}'
            },
            "process",
            :auto
          )
          subscriber.send(:leave_mongo_breadcrumb, event_name, event)
        end

        it "adds a JSON string of sort data" do
          command["sort"] = {"a" => 1, "b" => -1}
          expect(subscriber).to receive(:pop_command).with("123456").and_return(command)
          expect(Bugsnag).to receive(:leave_breadcrumb).with(
            "Mongo query #{event_name}",
            {
              :event_name => "mongo.#{event_name}",
              :command_name => "command",
              :database_name => "database",
              :operation_id => "1234567890",
              :request_id => "123456",
              :duration => "123.456",
              :collection => "collection_name_command",
              :sort => '{"a":1,"b":-1}'
            },
            "process",
            :auto
          )
          subscriber.send(:leave_mongo_breadcrumb, event_name, event)
        end
      end
    end

    describe "#sanitize_filter_hash" do
      it "calls into #sanitize_filter_value with the value from each {k,v} pair" do
        expect(subscriber.send(:sanitize_filter_hash, {:a => 1, :b => 2})).to eq({:a => '?', :b => '?'})
      end
    end

    describe "#sanitize_filter_value" do
      it "returns '?' for strings, numbers, booleans, and nil" do
        expect(subscriber.send(:sanitize_filter_value, 523, 0)).to eq('?')
        expect(subscriber.send(:sanitize_filter_value, "string", 0)).to eq('?')
        expect(subscriber.send(:sanitize_filter_value, true, 0)).to eq('?')
        expect(subscriber.send(:sanitize_filter_value, nil, 0)).to eq('?')
      end

      it "is recursive and iterative for array values" do
        expect(subscriber.send(:sanitize_filter_value, [1, [2, [3]]], 0)).to eq(['?', ['?', ['?']]])
      end

      it "calls #sanitize_filter_hash for hash values" do
        expect(subscriber).to receive(:sanitize_filter_hash).with({:a => 1}, 1)
        subscriber.send(:sanitize_filter_value, {:a => 1}, 0)
      end

      it "returns [MAX_FILTER_DEPTH_REACHED] if the filter depth is exceeded" do
        expect(subscriber.send(:sanitize_filter_value, 1, 4)).to eq('[MAX_FILTER_DEPTH_REACHED]')
      end
    end

    describe "#leave_command" do
      it "extracts and stores the command by request_id" do
        request_id = "123456"
        command = "this is a command string"
        event = double(:command => command, :request_id => request_id)

        subscriber.send(:leave_command, event)
        command_hash = Bugsnag.configuration.request_data[Bugsnag::MongoBreadcrumbSubscriber::MONGO_COMMAND_KEY]
        expect(command_hash[request_id]).to eq(command)
      end
    end

    describe "#pop_command" do
      let(:request_id) { "123456" }
      let(:command) { "this is a command string" }
      before do
        event = double(:command => command, :request_id => request_id)
        subscriber.send(:leave_command, event)
      end

      it "returns the command given a request_id" do
        expect(subscriber.send(:pop_command, request_id)).to eq(command)
      end

      it "removes the command from the request_data" do
        subscriber.send(:pop_command, request_id)
        command_hash = Bugsnag.configuration.request_data[Bugsnag::MongoBreadcrumbSubscriber::MONGO_COMMAND_KEY]
        expect(command_hash).not_to have_key(request_id)
      end

      it "returns nil if the request_id is not found" do
        expect(subscriber.send(:pop_command, "09876")).to be_nil
      end
    end

    describe "#event_commands" do
      it "returns a hash" do
        expect(subscriber.send(:event_commands)).to be_a(Hash)
      end

      it "is stored in request data" do
        subscriber.send(:event_commands)[:key] = "value"
        command_hash = Bugsnag.configuration.request_data[Bugsnag::MongoBreadcrumbSubscriber::MONGO_COMMAND_KEY]
        expect(command_hash[:key]).to eq("value")
      end
    end
  end

  after do
    Object.send(:remove_const, :Mongo) if @mocked_mongo
    module Kernel
      alias_method :require, :old_require
    end
  end
end
