require 'spec_helper'
require 'bugsnag/utility/metadata_delegate'
require 'support/shared_examples_for_metadata'

RSpec.describe Bugsnag::Utility::MetadataDelegate do
  include_examples(
    'metadata delegate',
    Bugsnag::Utility::MetadataDelegate.new.method(:add_metadata),
    Bugsnag::Utility::MetadataDelegate.new.method(:clear_metadata)
  )
end
