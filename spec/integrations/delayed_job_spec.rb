# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Delayed::Plugins::Bugsnag do
  describe '#error' do
    it 'should not raise exception' do
      payload = Object.new
      payload.extend(described_class::Notify)
      expect do
        payload.error(double('job', id: 1, payload_object: nil), '')
      end.not_to raise_error
    end
  end
end
