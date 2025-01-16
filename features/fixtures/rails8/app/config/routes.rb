Rails.application.routes.draw do
  get '/', to: 'application#index'

  get 'unhandled/error', to: 'unhandled#error'
  get 'unhandled/error_in_active_record_callback', to: 'unhandled#error_in_active_record_callback'

  get 'handled/unthrown', to: 'handled#unthrown'
  get 'handled/thrown', to: 'handled#thrown'
  get 'handled/string_notify', to: 'handled#string_notify'

  get 'before_notify/handled', to: 'before_notify#handled'
  get 'before_notify/unhandled', to: 'before_notify#unhandled'
  get 'before_notify/inline', to: 'before_notify#inline'

  get 'api_key/environment', to: 'api_key#environment'
  get 'api_key/changing', to: 'api_key#changing'

  get 'app_type/handled', to: 'app_type#handled'
  get 'app_type/unhandled', to: 'app_type#unhandled'
  get 'app_type/initializer', to: 'app_type#initializer'
  get 'app_type/after', to: 'app_type#after'

  get 'app_version/default', to: 'app_version#default'
  get 'app_version/initializer', to: 'app_version#initializer'
  get 'app_version/after', to: 'app_version#after'

  get 'auto_notify/unhandled', to: 'auto_notify#unhandled'
  get 'auto_notify/handled', to: 'auto_notify#handled'
  get 'auto_notify/unhandled_after', to: 'auto_notify#unhandled_after'
  get 'auto_notify/handled_after', to: 'auto_notify#handled_after'

  get 'project_root/default', to: 'project_root#default'
  get 'project_root/initializer', to: 'project_root#initializer'
  get 'project_root/after', to: 'project_root#after'

  get 'ignore_classes/initializer', to: 'ignore_classes#initializer'
  get 'ignore_classes/after', to: 'ignore_classes#after'

  get 'metadata_filters/filter', to: 'metadata_filters#filter'

  get 'session_tracking/initializer', to: 'session_tracking#initializer'
  get 'session_tracking/manual', to: 'session_tracking#manual'
  get 'session_tracking/multi_sessions', to: 'session_tracking#multi_sessions'

  get 'release_stage/default', to: 'release_stage#default'
  get 'release_stage/after', to: 'release_stage#after'

  get 'send_code/initializer', to: 'send_code#initializer'
  get 'send_code/after', to: 'send_code#after'

  get 'send_environment/initializer', to: 'send_environment#initializer'

  get 'clearance/create', to: 'clearance#create'
  get 'clearance/unhandled', to: 'clearance#unhandled'
  get 'clearance/handled', to: 'clearance#handled'

  get 'breadcrumbs/handled', to: 'breadcrumbs#handled'
  get 'breadcrumbs/sql_breadcrumb', to: 'breadcrumbs#sql_breadcrumb'
  get 'breadcrumbs/active_job', to: 'breadcrumbs#active_job'
  get 'breadcrumbs/cache_read', to: 'breadcrumbs#cache_read'

  get 'mongo/success_crash', to: 'mongo#success_crash'
  get 'mongo/get_crash', to: 'mongo#get_crash'
  get 'mongo/failure_crash', to: 'mongo#failure_crash'

  get 'active_job/handled', to: 'active_job#handled'
  get 'active_job/unhandled', to: 'active_job#unhandled'

  get 'features/handled', to: 'feature_flags#handled'
  get 'features/unhandled', to: 'feature_flags#unhandled'
end
