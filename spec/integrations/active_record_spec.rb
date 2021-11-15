require 'spec_helper'
require "bugsnag/integrations/rails/active_record_rescue"
describe Bugsnag::Rails::ActiveRecordRescue do
  it "does not include module in rails 5 and newer" do
    if ::Rails::VERSION::MAJOR < 5
      skip "test not for this version"
    else
      expect(ActiveRecord::Base.ancestors).not_to include(Bugsnag::Rails::ActiveRecordRescue)
    end
  end

  it "includes it if the exception behavior is to not raise" do
    if ::Rails::VERSION::MAJOR != 4
      skip "test not for this version"
    else
      ActiveRecord::Base.errors_in_transactional_callbacks = :log
      expect(ActiveRecord::Base.ancestors).to include(Bugsnag::Rails::ActiveRecordRescue)
    end
  end

  it "does not include it if the exception behavior is to raise" do
    if ::Rails::VERSION::MAJOR != 4
      skip "test not for this version"
    else
      ActiveRecord::Base.errors_in_transactional_callbacks = :raise
      expect(ActiveRecord::Base.ancestors).not_to include(Bugsnag::Rails::ActiveRecordRescue)
    end
  end

  it "includes it in rails 3" do
    if ::Rails::VERSION::MAJOR != 3
      skip "test not for this version"
    else
      expect(ActiveRecord::Base.ancestors).to include(Bugsnag::Rails::ActiveRecordRescue)
    end
  end
end
