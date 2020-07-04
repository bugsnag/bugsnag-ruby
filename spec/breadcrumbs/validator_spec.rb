# encoding: utf-8
require 'spec_helper'

require 'bugsnag/breadcrumbs/breadcrumb'
require 'bugsnag/breadcrumbs/validator'

RSpec.describe Bugsnag::Breadcrumbs::Validator do
  let(:enabled_automatic_breadcrumb_types) { Bugsnag::Breadcrumbs::VALID_BREADCRUMB_TYPES }
  let(:auto) { false }
  let(:name) { "Valid message" }
  let(:type) { Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE }
  let(:meta_data) { {} }

  describe "#validate" do
    it "does not 'ignore!' a valid breadcrumb" do
      config = instance_double(Bugsnag::Configuration)
      allow(config).to receive(:enabled_automatic_breadcrumb_types).and_return(enabled_automatic_breadcrumb_types)
      validator = Bugsnag::Breadcrumbs::Validator.new(config)

      breadcrumb = instance_double(Bugsnag::Breadcrumbs::Breadcrumb, {
        :auto => auto,
        :name => name,
        :type => type,
        :meta_data => meta_data,
        :meta_data= => nil
      })

      expect(breadcrumb).to_not receive(:ignore!)
      expect(config).to_not receive(:debug)

      validator.validate(breadcrumb)
    end

    describe "tests meta_data types" do
      it "accepts Strings, Numerics, Booleans, & nil" do
        config = instance_double(Bugsnag::Configuration)
        allow(config).to receive(:enabled_automatic_breadcrumb_types).and_return(enabled_automatic_breadcrumb_types)
        validator = Bugsnag::Breadcrumbs::Validator.new(config)

        meta_data = {
          :string => "This is a string",
          :symbol => :this_is_a_symbol,
          :integer => 12345,
          :float => 12345.6789,
          :false => false,
          :true => true,
          :nil => nil
        }

        breadcrumb = instance_double(Bugsnag::Breadcrumbs::Breadcrumb, {
          :auto => auto,
          :name => name,
          :type => type,
          :meta_data => meta_data,
          :meta_data= => nil
        })

        expect(breadcrumb).to_not receive(:ignore!)
        expect(config).to_not receive(:debug)

        validator.validate(breadcrumb)
      end

      it "rejects Arrays, Hashes, and non-primitive objects" do
        config = instance_double(Bugsnag::Configuration)
        allow(config).to receive(:enabled_automatic_breadcrumb_types).and_return(enabled_automatic_breadcrumb_types)
        validator = Bugsnag::Breadcrumbs::Validator.new(config)

        class TestClass
        end

        meta_data = {
          :fine => 1,
          :array => [1, 2, 3],
          :hash => {
            :a => 1
          },
          :object => TestClass.new
        }

        breadcrumb = instance_double(Bugsnag::Breadcrumbs::Breadcrumb, {
          :auto => auto,
          :name => name,
          :type => type,
          :meta_data => meta_data
        })

        expect(breadcrumb).to_not receive(:ignore!)
        expected_string_1 = "Breadcrumb #{breadcrumb.name} meta_data array:Array has been dropped for having an invalid data type"
        expected_string_2 = "Breadcrumb #{breadcrumb.name} meta_data hash:Hash has been dropped for having an invalid data type"
        expected_string_3 = "Breadcrumb #{breadcrumb.name} meta_data object:TestClass has been dropped for having an invalid data type"
        expect(config).to receive(:debug).with(expected_string_1)
        expect(config).to receive(:debug).with(expected_string_2)
        expect(config).to receive(:debug).with(expected_string_3)

        # Confirms that the meta_data is being filtered
        expect(breadcrumb).to receive(:meta_data=).with({
          :fine => 1
        })

        validator.validate(breadcrumb)
      end
    end

    it "tests type, defaulting to 'manual' if invalid" do
      config = instance_double(Bugsnag::Configuration)
      allow(config).to receive(:enabled_automatic_breadcrumb_types).and_return(enabled_automatic_breadcrumb_types)
      validator = Bugsnag::Breadcrumbs::Validator.new(config)

      type = "Not a valid type"

      breadcrumb = instance_double(Bugsnag::Breadcrumbs::Breadcrumb, {
        :auto => auto,
        :name => name,
        :type => type,
        :meta_data => meta_data,
        :meta_data= => nil
      })

      expect(breadcrumb).to receive(:type=).with(Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE)
      expect(breadcrumb).to_not receive(:ignore!)
      expected_string = "Invalid type: #{type} for breadcrumb: #{breadcrumb.name}, defaulting to #{Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE}"
      expect(config).to receive(:debug).with(expected_string)

      validator.validate(breadcrumb)
    end

    describe "with enabled_automatic_breadcrumb_types set" do
      it "rejects automatic breadcrumbs with rejected types" do
        config = instance_double(Bugsnag::Configuration)
        allowed_breadcrumb_types = []
        allow(config).to receive(:enabled_automatic_breadcrumb_types).and_return(allowed_breadcrumb_types)
        validator = Bugsnag::Breadcrumbs::Validator.new(config)

        auto = true
        type = Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE

        breadcrumb = instance_double(Bugsnag::Breadcrumbs::Breadcrumb, {
          :auto => auto,
          :name => name,
          :type => type,
          :meta_data => meta_data,
          :meta_data= => nil
        })

        expect(breadcrumb).to receive(:ignore!)
        expected_string = "Automatic breadcrumb of type #{Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE} ignored: #{breadcrumb.name}"
        expect(config).to receive(:debug).with(expected_string)

        validator.validate(breadcrumb)
      end

      it "does not reject manual breadcrumbs with rejected types" do
        config = instance_double(Bugsnag::Configuration)
        allowed_breadcrumb_types = []
        allow(config).to receive(:enabled_automatic_breadcrumb_types).and_return(allowed_breadcrumb_types)
        validator = Bugsnag::Breadcrumbs::Validator.new(config)

        type = Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE

        breadcrumb = instance_double(Bugsnag::Breadcrumbs::Breadcrumb, {
          :auto => auto,
          :name => name,
          :type => type,
          :meta_data => meta_data,
          :meta_data= => nil
        })

        expect(breadcrumb).to_not receive(:ignore!)
        expect(config).to_not receive(:debug)

        validator.validate(breadcrumb)
      end
    end
  end
end
