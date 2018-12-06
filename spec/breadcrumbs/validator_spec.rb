# encoding: utf-8
require 'spec_helper'

require 'bugsnag/breadcrumbs/breadcrumbs'
require 'bugsnag/breadcrumbs/validator'

RSpec.describe Bugsnag::Breadcrumbs::Validator do
  before do
    @automatic_breadcrumb_types = [
      Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE,
      Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE,
      Bugsnag::Breadcrumbs::NAVIGATION_BREADCRUMB_TYPE,
      Bugsnag::Breadcrumbs::REQUEST_BREADCRUMB_TYPE,
      Bugsnag::Breadcrumbs::PROCESS_BREADCRUMB_TYPE,
      Bugsnag::Breadcrumbs::LOG_BREADCRUMB_TYPE,
      Bugsnag::Breadcrumbs::USER_BREADCRUMB_TYPE,
      Bugsnag::Breadcrumbs::STATE_BREADCRUMB_TYPE
    ]

    @breadcrumb_auto = false
    @breadcrumb_message = "Valid message"
    @breadcrumb_type = Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE
    @breadcrumb_meta_data = {}
  end

  describe "#validate" do
    it "does not 'ignore!' a valid breadcrumb" do
      config = double
      allow(config).to receive(:automatic_breadcrumb_types).and_return(@automatic_breadcrumb_types)
      validator = Bugsnag::Breadcrumbs::Validator.new(config)

      breadcrumb = double
      allow(breadcrumb).to receive_messages({
        :auto => @breadcrumb_auto,
        :message => @breadcrumb_message,
        :type => @breadcrumb_type,
        :meta_data => @breadcrumb_meta_data
      })

      expect(breadcrumb).to_not receive(:ignore!)
      expect(config).to_not receive(:warn)

      validator.validate(breadcrumb)
    end

    it "trims long messages to length and warns" do
      config = double
      allow(config).to receive(:automatic_breadcrumb_types).and_return(@automatic_breadcrumb_types)
      validator = Bugsnag::Breadcrumbs::Validator.new(config)

      breadcrumb = double

      long_message = "1234567890123456789012345678901234567890"

      allow(breadcrumb).to receive_messages({
        :auto => @breadcrumb_auto,
        :message => long_message,
        :type => @breadcrumb_type,
        :meta_data => @breadcrumb_meta_data
      })

      expect(breadcrumb).to_not receive(:ignore!)
      expected_string = "Breadcrumb message trimmed to length 30.  Original message: #{long_message}"
      expect(config).to receive(:warn).with(expected_string)

      validator.validate(breadcrumb)

      expect(breadcrumb.message).to eq("123456789012345678901234567890")
    end

    describe "tests meta_data types" do
      it "accepts Strings, Numerics, & Booleans" do
        config = double
        allow(config).to receive(:automatic_breadcrumb_types).and_return(@automatic_breadcrumb_types)
        validator = Bugsnag::Breadcrumbs::Validator.new(config)

        breadcrumb = double

        meta_data = {
          :string => "This is a string",
          :integer => 12345,
          :float => 12345.6789,
          :false => false,
          :true => true
        }

        allow(breadcrumb).to receive_messages({
          :auto => @breadcrumb_auto,
          :message => @breadcrumb_message,
          :type => @breadcrumb_type,
          :meta_data => meta_data
        })

        expect(breadcrumb).to_not receive(:ignore!)
        expect(config).to_not receive(:warn)

        validator.validate(breadcrumb)
      end

      it "rejects Arrays" do
        config = double
        allow(config).to receive(:automatic_breadcrumb_types).and_return(@automatic_breadcrumb_types)
        validator = Bugsnag::Breadcrumbs::Validator.new(config)

        breadcrumb = double

        meta_data = {
          :array => [1, 2, 3]
        }

        allow(breadcrumb).to receive_messages({
          :auto => @breadcrumb_auto,
          :message => @breadcrumb_message,
          :type => @breadcrumb_type,
          :meta_data => meta_data
        })

        expect(breadcrumb).to receive(:meta_data=).with({})
        expect(breadcrumb).to_not receive(:ignore!)
        expected_string = "Breadcrumb #{@breadcrumb_message} meta_data has values other than strings, numbers, or booleans, dropping: #{meta_data}"
        expect(config).to receive(:warn).with(expected_string)

        validator.validate(breadcrumb)
      end

      it "rejects Hashes" do
        config = double
        allow(config).to receive(:automatic_breadcrumb_types).and_return(@automatic_breadcrumb_types)
        validator = Bugsnag::Breadcrumbs::Validator.new(config)

        breadcrumb = double

        meta_data = {
          :hash => {
            :a => 1,
            :b => 2
          }
        }

        allow(breadcrumb).to receive_messages({
          :auto => @breadcrumb_auto,
          :message => @breadcrumb_message,
          :type => @breadcrumb_type,
          :meta_data => meta_data
        })

        expect(breadcrumb).to receive(:meta_data=).with({})
        expect(breadcrumb).to_not receive(:ignore!)
        expected_string = "Breadcrumb #{@breadcrumb_message} meta_data has values other than strings, numbers, or booleans, dropping: #{meta_data}"
        expect(config).to receive(:warn).with(expected_string)

        validator.validate(breadcrumb)
      end

      it "rejects non-primative objects" do
        config = double
        allow(config).to receive(:automatic_breadcrumb_types).and_return(@automatic_breadcrumb_types)
        validator = Bugsnag::Breadcrumbs::Validator.new(config)

        breadcrumb = double

        class TestClass
        end

        meta_data = {
          :class => TestClass.new
        }

        allow(breadcrumb).to receive_messages({
          :auto => @breadcrumb_auto,
          :message => @breadcrumb_message,
          :type => @breadcrumb_type,
          :meta_data => meta_data
        })

        expect(breadcrumb).to receive(:meta_data=).with({})
        expect(breadcrumb).to_not receive(:ignore!)
        expected_string = "Breadcrumb #{@breadcrumb_message} meta_data has values other than strings, numbers, or booleans, dropping: #{meta_data}"
        expect(config).to receive(:warn).with(expected_string)

        validator.validate(breadcrumb)
      end
    end

    it "tests type, defaulting to 'manual' if invalid" do
      config = double
      allow(config).to receive(:automatic_breadcrumb_types).and_return(@automatic_breadcrumb_types)
      validator = Bugsnag::Breadcrumbs::Validator.new(config)

      breadcrumb = double

      incorrect_type = "Not a valid type"

      allow(breadcrumb).to receive_messages({
        :auto => @breadcrumb_auto,
        :message => @breadcrumb_message,
        :type => incorrect_type,
        :meta_data => @breadcrumb_meta_data
      })

      expect(breadcrumb).to receive(:type=).with(Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE)
      expect(breadcrumb).to_not receive(:ignore!)
      expected_string = "Invalid type: #{incorrect_type} for breadcrumb: #{@breadcrumb_message}, defaulting to #{Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE}"
      expect(config).to receive(:warn).with(expected_string)

      validator.validate(breadcrumb)
    end

    describe "with automatic_breadcrumb_types set" do
      it "rejects automatic breadcrumbs with rejected types" do
        config = double
        allowed_breadcrumb_types = []
        allow(config).to receive(:automatic_breadcrumb_types).and_return(allowed_breadcrumb_types)
        validator = Bugsnag::Breadcrumbs::Validator.new(config)

        breadcrumb = double

        allow(breadcrumb).to receive_messages({
          :auto => true,
          :message => @breadcrumb_message,
          :type => Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE,
          :meta_data => @breadcrumb_meta_data
        })

        expect(breadcrumb).to receive(:ignore!)
        expected_string = "Automatic breadcrumb of type #{Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE} ignored: #{breadcrumb.message}"
        expect(config).to receive(:warn).with(expected_string)

        validator.validate(breadcrumb)
      end

      it "does not reject manual breadcrumbs with rejected types" do
        config = double
        allowed_breadcrumb_types = []
        allow(config).to receive(:automatic_breadcrumb_types).and_return(allowed_breadcrumb_types)
        validator = Bugsnag::Breadcrumbs::Validator.new(config)

        breadcrumb = double

        allow(breadcrumb).to receive_messages({
          :auto => false,
          :message => @breadcrumb_message,
          :type => Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE,
          :meta_data => @breadcrumb_meta_data
        })

        expect(breadcrumb).to_not receive(:ignore!)
        expect(config).to_not receive(:warn)

        validator.validate(breadcrumb)
      end
    end
  end
end