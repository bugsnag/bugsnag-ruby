Gem::Specification.new do |s|
  s.name = "bugsnag"
  s.version = File.read("VERSION").strip

  s.authors = ["James Smith"]
  s.email = "james@bugsnag.com"

  s.description = "Ruby notifier for bugsnag.com"
  s.summary = "Ruby notifier for bugsnag.com"
  s.homepage = "http://github.com/bugsnag/bugsnag-ruby"
  s.licenses = ["MIT"]

  s.files = `git ls-files`.split("\n").reject {|file| file.start_with? "example/"}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md"
  ]
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 1.9.2'

  s.add_development_dependency 'rake', '~> 10.1.1'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'addressable', '~> 2.3.8'
  s.add_development_dependency 'webmock', '2.1.0'
  s.add_development_dependency 'delayed_job'
  s.add_development_dependency 'activesupport', '~> 4.2.10'
end
