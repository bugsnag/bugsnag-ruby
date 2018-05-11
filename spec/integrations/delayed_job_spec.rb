# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Delayed::Plugins::Bugsnag do
  describe '#error' do
    it 'should set metadata correctly with max_attempts' do
      payload = Object.new
      payload.extend(described_class::Notify)
      job = double
      allow(job).to receive_messages(
        :id => "TEST",
        :queue => "TEST_QUEUE",
        :attempts => 0,
        :max_attempts => 3,
        :payload_object => {
          :id => "PAYLOAD_ID",
          :display_name => "PAYLOAD_DISPLAY_NAME",
          :method_name => "PAYLOAD_METHOD_NAME",
          :args => [
            "SOME",
            "TEST",
            "ARGS"
          ]
        }
      )

      expect do
        payload.error(job, '')
      end.not_to raise_error

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["severity"]).to eq("error")
        expect(event["severityReason"]).to eq({
          "type" => "unhandledExceptionMiddleware",
          "attributes" => {
            "framework" => "DelayedJob"
          }
        })
        expect(event["metaData"]["job"]).to eq({
          "class" => job.class.name,
          "id" => "TEST",
          "queue" => "TEST_QUEUE",
          "attempts" => "1 / 3",
          "payload" => {
            "class" => {}.class.name,
            "args" => {
              "id" => "PAYLOAD_ID",
              "display_name" => "PAYLOAD_DISPLAY_NAME",
              "method_name" => "PAYLOAD_METHOD_NAME",
              "args" => [
                "SOME",
                "TEST",
                "ARGS"
              ]
            }
          }
        })
      }
    end

    it 'should set metadata correctly without max_attempts' do
      payload = Object.new
      payload.extend(described_class::Notify)
      job = double
      allow(job).to receive_messages(
        :id => "TEST",
        :queue => "TEST_QUEUE",
        :attempts => 0,
        :payload_object => {
          :id => "PAYLOAD_ID",
          :display_name => "PAYLOAD_DISPLAY_NAME",
          :method_name => "PAYLOAD_METHOD_NAME",
          :args => [
            "SOME",
            "TEST",
            "ARGS"
          ]
        }
      )

      expect do
        payload.error(job, '')
      end.not_to raise_error

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["severity"]).to eq("error")
        expect(event["severityReason"]).to eq({
          "type" => "unhandledExceptionMiddleware",
          "attributes" => {
            "framework" => "DelayedJob"
          }
        })
        expect(event["metaData"]["job"]).to eq({
          "class" => job.class.name,
          "id" => "TEST",
          "queue" => "TEST_QUEUE",
          "attempts" => "1 / #{Delayed::Worker.max_attempts}",
          "payload" => {
            "class" => {}.class.name,
            "args" => {
              "id" => "PAYLOAD_ID",
              "display_name" => "PAYLOAD_DISPLAY_NAME",
              "method_name" => "PAYLOAD_METHOD_NAME",
              "args" => [
                "SOME",
                "TEST",
                "ARGS"
              ]
            }
          }
        })
      }
    end
  end
end
