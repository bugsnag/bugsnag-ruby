Bundler.require

run InitializerConfigApp ||= Class.new(Rails::Application) {
  config.secret_key_base = routes.append {
    root to: proc {
      [200, {"Content-Type" => "text/plain"}, ["Hello!"]]
    }
  }.to_s

  config.cache_classes = true
  config.eager_load = true
  config.logger = Logger.new(STDOUT)
  config.log_level = :warn

  initialize!
}
