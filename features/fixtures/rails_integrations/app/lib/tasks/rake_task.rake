namespace :rake_task do
  task :raise => :environment do
    raise 'oh no!'
  end
end
