Gem::Specification.new do |s|
  s.name = "bugsnag"
  s.version = File.read("VERSION").strip

  s.authors = ["James Smith"]
  s.email = "james@bugsnag.com"

  s.description = "Ruby notifier for bugsnag.com"
  s.summary = "Ruby notifier for bugsnag.com"
  s.homepage = "http://github.com/bugsnag/bugsnag-ruby"
  s.licenses = ["MIT"]

  s.files = `git ls-files`.split("\n")
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'multi_json', ["~> 1.0"]

  if RUBY_VERSION < "1.9"
    # Use ruby 1.8 compatible httparty
    s.add_runtime_dependency 'httparty', ["< 0.12.0", ">= 0.6"]
    s.add_development_dependency "rake", "~> 10.1.1"
  else
    s.add_runtime_dependency 'httparty', ["< 1.0", ">= 0.6"]
    s.add_development_dependency 'rake'
  end

  s.add_development_dependency 'rspec', ">= 3.0.0"
  s.add_development_dependency 'rspec-its'
  s.add_development_dependency 'rspec-mocks'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'pry'
end

