require "spec_helper"

require "bugsnag/endpoint_configuration"
require "bugsnag/endpoint_validator"

describe Bugsnag::EndpointValidator do
  describe "#validate" do
    it "returns an invalid result if given nil" do
      result = Bugsnag::EndpointValidator.validate(nil)

      expect(result).to have_attributes({
        valid?: false,
        keep_events_enabled_for_backwards_compatibility?: false,
        reason: Bugsnag::EndpointValidator::Result::MISSING_URLS,
      })
    end

    it "returns an invalid result if no URL is set" do
      endpoint_configuration = Bugsnag::EndpointConfiguration.new(nil, nil)
      result = Bugsnag::EndpointValidator.validate(endpoint_configuration)

      expect(result).to have_attributes({
        valid?: false,
        keep_events_enabled_for_backwards_compatibility?: false,
        reason: Bugsnag::EndpointValidator::Result::MISSING_URLS,
      })
    end

    it "returns an invalid result if notify URL is not set" do
      endpoint_configuration = Bugsnag::EndpointConfiguration.new(nil, "sessions.example.com")
      result = Bugsnag::EndpointValidator.validate(endpoint_configuration)

      expect(result).to have_attributes({
        valid?: false,
        keep_events_enabled_for_backwards_compatibility?: false,
        reason: Bugsnag::EndpointValidator::Result::MISSING_NOTIFY_URL,
      })
    end

    it "returns an invalid result if session URL is not set" do
      endpoint_configuration = Bugsnag::EndpointConfiguration.new("notify.example.com", nil)
      result = Bugsnag::EndpointValidator.validate(endpoint_configuration)

      expect(result).to have_attributes({
        valid?: false,
        keep_events_enabled_for_backwards_compatibility?: true,
        reason: Bugsnag::EndpointValidator::Result::MISSING_SESSION_URL,
      })
    end

    it "returns an invalid result if both URLs are empty" do
      endpoint_configuration = Bugsnag::EndpointConfiguration.new("", "")
      result = Bugsnag::EndpointValidator.validate(endpoint_configuration)

      expect(result).to have_attributes({
        valid?: false,
        keep_events_enabled_for_backwards_compatibility?: false,
        reason: Bugsnag::EndpointValidator::Result::INVALID_URLS,
      })
    end

    it "returns an invalid result if notify URL is empty" do
      endpoint_configuration = Bugsnag::EndpointConfiguration.new("", "session.example.com")
      result = Bugsnag::EndpointValidator.validate(endpoint_configuration)

      expect(result).to have_attributes({
        valid?: false,
        keep_events_enabled_for_backwards_compatibility?: false,
        reason: Bugsnag::EndpointValidator::Result::INVALID_NOTIFY_URL,
      })
    end

    it "returns an invalid result if session URL is empty" do
      endpoint_configuration = Bugsnag::EndpointConfiguration.new("notify.example.com", "")
      result = Bugsnag::EndpointValidator.validate(endpoint_configuration)

      expect(result).to have_attributes({
        valid?: false,
        keep_events_enabled_for_backwards_compatibility?: true,
        reason: Bugsnag::EndpointValidator::Result::INVALID_SESSION_URL,
      })
    end

    it "returns a valid result when given two valid URLs" do
      endpoint_configuration = Bugsnag::EndpointConfiguration.new("notify.example.com", "session.example.com")
      result = Bugsnag::EndpointValidator.validate(endpoint_configuration)

      expect(result).to have_attributes({
        valid?: true,
        keep_events_enabled_for_backwards_compatibility?: true,
        reason: nil,
      })
    end

    it "returns a valid result when given two non-empty strings" do
      endpoint_configuration = Bugsnag::EndpointConfiguration.new("a b c", "x y z")
      result = Bugsnag::EndpointValidator.validate(endpoint_configuration)

      expect(result).to have_attributes({
        valid?: true,
        keep_events_enabled_for_backwards_compatibility?: true,
        reason: nil,
      })
    end
  end
end
