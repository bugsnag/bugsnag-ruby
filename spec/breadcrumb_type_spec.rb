require "spec_helper"

require "bugsnag/breadcrumb_type"
require "bugsnag/breadcrumbs/breadcrumbs"

describe Bugsnag::BreadcrumbType do
  it "contains constants equivalent to the breadcrumb types defined in Bugsnag::Breadcrumbs" do
    expect(Bugsnag::BreadcrumbType::ERROR).to eq(Bugsnag::Breadcrumbs::ERROR_BREADCRUMB_TYPE)
    expect(Bugsnag::BreadcrumbType::LOG).to eq(Bugsnag::Breadcrumbs::LOG_BREADCRUMB_TYPE)
    expect(Bugsnag::BreadcrumbType::MANUAL).to eq(Bugsnag::Breadcrumbs::MANUAL_BREADCRUMB_TYPE)
    expect(Bugsnag::BreadcrumbType::NAVIGATION).to eq(Bugsnag::Breadcrumbs::NAVIGATION_BREADCRUMB_TYPE)
    expect(Bugsnag::BreadcrumbType::PROCESS).to eq(Bugsnag::Breadcrumbs::PROCESS_BREADCRUMB_TYPE)
    expect(Bugsnag::BreadcrumbType::REQUEST).to eq(Bugsnag::Breadcrumbs::REQUEST_BREADCRUMB_TYPE)
    expect(Bugsnag::BreadcrumbType::STATE).to eq(Bugsnag::Breadcrumbs::STATE_BREADCRUMB_TYPE)
    expect(Bugsnag::BreadcrumbType::USER).to eq(Bugsnag::Breadcrumbs::USER_BREADCRUMB_TYPE)
  end

  it "defines the same number of breadcrumb type constants" do
    old_types = Bugsnag::Breadcrumbs.constants.select { |type| type.to_s.end_with?("_BREADCRUMB_TYPE") }

    expect(Bugsnag::BreadcrumbType.constants.length).to eq(old_types.length)
  end
end
