namespace :sidekiq_tests do
  task :handled_error do
    run_sidekiq_test('./initializers/HandledError.rb')
  end

  task :unhandled_error do
    run_sidekiq_test('./initializers/UnhandledError.rb')
  end
end

def run_sidekiq_test(command)
  system("ruby #{command}")
  system("sidekiq -r ./app.rb")
end