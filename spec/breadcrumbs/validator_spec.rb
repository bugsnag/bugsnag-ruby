# encoding: utf-8
require 'spec_helper'

require 'bugsnag/breadcrumbs/breadcrumb'
require 'bugsnag/breadcrumbs/validator'

RSpec.describe Bugsnag::Breadcrumbs::Validator do
  let(:auto) { :manual }
  let(:name) { "Valid message" }
  let(:type) { Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE }

  describe "#validate" do
    it "does not 'ignore!' a valid breadcrumb" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(name, type, {}, auto)

      expect(breadcrumb.ignore?).to eq(false)

      validator = Bugsnag::Breadcrumbs::Validator.new(Bugsnag.configuration)
      validator.validate(breadcrumb)

      expect(breadcrumb.ignore?).to eq(false)
    end

    it "tests type, defaulting to 'manual' if invalid" do
      invalid_type = "I'm not a valid type :-)"
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(name, invalid_type, {}, auto)

      expect(breadcrumb.ignore?).to eq(false)
      expect(breadcrumb.type).to eq(invalid_type)

      validator = Bugsnag::Breadcrumbs::Validator.new(Bugsnag.configuration)
      validator.validate(breadcrumb)

      expect(breadcrumb.ignore?).to eq(false)
      expect(breadcrumb.type).to eq(Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE)
    end

    describe "with enabled_automatic_breadcrumb_types set" do
      it "rejects automatic breadcrumbs with rejected types" do
        Bugsnag.configuration.logger = spy(Logger)
        Bugsnag.configuration.enabled_automatic_breadcrumb_types.delete(type)

        breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(name, type, {}, :auto)

        expect(breadcrumb.ignore?).to eq(false)

        validator = Bugsnag::Breadcrumbs::Validator.new(Bugsnag.configuration)
        validator.validate(breadcrumb)

        expect(breadcrumb.ignore?).to eq(true)

        expect(Bugsnag.configuration.logger).to have_received(:debug) do |&block|
          expect(block.call).to eq("Automatic breadcrumb of type #{type} ignored: #{name}")
        end
      end

      it "does not reject manual breadcrumbs with rejected types" do
        Bugsnag.configuration.logger = spy(Logger)
        Bugsnag.configuration.enabled_automatic_breadcrumb_types.delete(type)

        breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(name, type, {}, :manual)

        expect(breadcrumb.ignore?).to eq(false)

        validator = Bugsnag::Breadcrumbs::Validator.new(Bugsnag.configuration)
        validator.validate(breadcrumb)

        expect(breadcrumb.ignore?).to eq(false)
        expect(Bugsnag.configuration.logger).to_not have_received(:debug)
      end
    end
  end
end
