Gem::Specification.new do |s|
  s.name = "bugsnag"
  s.version = File.read("VERSION").strip

  s.authors = ["James Smith"]
  s.email = "james@bugsnag.com"

  s.description = "Ruby notifier for bugsnag.com"
  s.summary = "Ruby notifier for bugsnag.com"
  s.homepage = "https://github.com/bugsnag/bugsnag-ruby"
  s.licenses = ["MIT"]

  s.files = `git ls-files -z lib bugsnag.gemspec VERSION .yardopts`.split("\x0")
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md"
  ]
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 1.9.2'

  ruby_version = Gem::Version.new(RUBY_VERSION.dup)

  if ruby_version < Gem::Version.new('2.2.0')
    # concurrent-ruby 1.1.10 requires Ruby 2.2+
    s.add_runtime_dependency 'concurrent-ruby', '~> 1.0', '< 1.1.10'
  else
    s.add_runtime_dependency 'concurrent-ruby', '~> 1.0'
  end
end
