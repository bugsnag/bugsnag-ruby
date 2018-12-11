require "bugnsag/breadcrumbs/breadcrumbs"

module Bugsnag::Railtie
  DEFAULT_RAILS_BREADCRUMBS = [
    {
      :id => "perform_action.action_cable",
      :message => "Perform ActionCable",
      :type => Bugsnag::Breadcrumbs::PROCESS_BREADCRUMB_TYPE,
      :allowed_data => [
        :event_id,
        :channel_class,
        :action,
        :data
      ]
    },
    {
      :id => "perform.active_job",
      :message => "Perform ActiveJob"
      :type => Bugsnag::Breadcrumbs::PROCESS_BREADCRUMB_TYPE,
      :allowed_data => [
        :event_id,
        :adapter,
        :job
      ]
    },
    {
      :id => "cache_read.active_support",
      :message => "Read cache",
      :type => Bugsnag::Breadcrumbs::PROCESS_BREADCRUMB_TYPE,
      :allowed_data => [
        :event_id,
        :key,
        :keys,
        :hit,
        :hits,
        :super_operation
      ]
    },
    {
      :id => "cache_fetch_hit.active_support",
      :message => "Fetch cache hit",
      :type => Bugsnag::Breadcrumbs::PROCESS_BREADCRUMB_TYPE,
      :allowed_data => [
        :event_id,
        :key,
        :keys
      ]
    },
    {
      :id => "sql.active_record",
      :message => "ActiveRecord SQL query",
      :type => Bugsnag::Breadcrumbs::PROCESS_BREADCRUMB_TYPE,
      :allowed_data => [
        :event_id,
        :name,
        :connection_id,
        :cached
      ]
    },
    {
      :id => "start_processing.action_controller",
      :message => "Controller started processing"
      :type => Bugsnag::Breadcrumbs::REQUEST_BREADCRUMB_TYPE,
      :allowed_data => [
        :event_id,
        :controller,
        :action,
        :path
      ]
    },
    {
      :id => "process_action.action_controller",
      :message => "Controller action processed",
      :type => Bugsnag::Breadcrumbs::REQUEST_BREADCRUMB_TYPE,
      :allowed_data => [
        :event_id,
        :controller,
        :action,
        :status,
        :view_runtime,
        :db_runtime
      ]
    },
    {
      :id => "redirect_to.action_controller",
      :message => "Controller redirect",
      :type => Bugsnag::Breadcrumbs::REQUEST_BREADCRUMB_TYPE,
      :allowed_data => [
        :event_id,
        :status,
        :location
      ]
    },
    {
      :id => "halted_callback.action_controller",
      :message => "Controller halted via callback",
      :type => Bugsnag::Breadcrumbs::REQUEST_BREADCRUMB_TYPE,
      :allowed_data => [
        :event_id,
        :filter
      ]
    },
    {
      :id => "render_template.action_view",
      :message => "ActionView template rendered"
      :type => Bugsnag::Breadcrumbs::REQUEST_BREADCRUMB_TYPE,
      :allowed_data => [
        :event_id,
        :identifier,
        :layout
      ]
    },
    {
      :id => "render_partial.action_view",
      :message => "ActionView partial rendered",
      :type => Bugsnag::Breadcrumbs::REQUEST_BREADCRUMB_TYPE,
      :allowed_data => [
        :event_id,
        :identifier
      ]
    },
    {
      :id => "deliver.action_mailer",
      :message => "ActionMail delivered",
      :type => Bugsnag::Breadcrumbs::REQUEST_BREADCRUMB_TYPE,
      :allowed_data => [
        :event_id,
        :mailer,
        :message_id,
        :subject,
        :to,
        :from,
        :bcc,
        :cc,
        :date
      ]
    }
  ]
end