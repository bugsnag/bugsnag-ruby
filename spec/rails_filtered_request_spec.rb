# Rails 2.x only
require 'spec_helper'
require 'bugsnag/rails/filtered_request'

class TestRails2ControllerBase
  # Simplified implementation of Rails 2 parameter filtering for test purposes.
  def self.filter_parameter_logging(*filter_words, &block)
    define_method(:filter_parameters) do |unfiltered_parameters|
      filtered_parameters = {}
      unfiltered_parameters.each do |key, value|
        filtered_parameters[key] = filter_words.include?(key) ? '[FILTERED]' : value
      end
      filtered_parameters
    end
  end
end

class UnfilteredTestRails2Controller < TestRails2ControllerBase
end

class FilteredTestRails2Controller < TestRails2ControllerBase
  filter_parameter_logging :ssn
end

describe Bugsnag::Rails::FilteredRequest do

  let(:filtered_request) { described_class.new(controller) }
  let(:incoming_request) { double("Request", request_attributes) }
  let(:request_attributes) do
    {
      :parameters => request_parameters,
      :session    => double("Session", :data => {}),
      :protocol   => "http://",
      :host       => "example.com",
      :fullpath   => "http://example.com/test"
    }
  end
  let(:request_parameters) do
    {
      :user_id  => 1,
      :ssn      => "999-99-9999"
    }
  end
  let(:controller) { FilteredTestRails2Controller.new }

  before { allow(controller).to receive(:request).and_return(incoming_request) }

  subject { filtered_request }

  shared_examples_for "other request attributes are delegated" do
    [:session, :protocol, :host, :fullpath].each do |attr|
      it { is_expected.to respond_to attr }
      its(attr) { is_expected.to eq request_attributes[attr] }
    end
  end

  its(:parameters) { is_expected.to eq(request_parameters.merge(:ssn => '[FILTERED]')) }
  it_behaves_like "other request attributes are delegated"

  context "when the controller has no filtering" do
    let(:controller) { UnfilteredTestRails2Controller.new }

    its(:parameters) { is_expected.to eq(request_parameters) }
    it_behaves_like "other request attributes are delegated"
  end

end