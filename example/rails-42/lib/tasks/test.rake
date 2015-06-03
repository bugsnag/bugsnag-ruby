namespace :test do
  task :uncaught => :environment do
    raise "Uncaught rake"
  end
end
