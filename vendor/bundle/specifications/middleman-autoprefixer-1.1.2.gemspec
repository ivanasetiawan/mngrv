# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "middleman-autoprefixer"
  s.version = "1.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dominik Porada"]
  s.date = "2014-04-21"
  s.email = ["dominik@porada.co"]
  s.homepage = "https://github.com/porada/middleman-autoprefixer"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.3"
  s.summary = "Autoprefixer integration with Middleman"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<middleman-core>, ["~> 3.2"])
      s.add_runtime_dependency(%q<middleman-sprockets>, ["~> 3.2"])
      s.add_runtime_dependency(%q<autoprefixer-rails>, ["~> 1.1.20140302"])
      s.add_development_dependency(%q<bundler>, ["~> 1.5"])
      s.add_development_dependency(%q<rake>, ["~> 10.1"])
      s.add_development_dependency(%q<middleman>, ["~> 3.2"])
      s.add_development_dependency(%q<cucumber>, ["~> 1.3.14"])
      s.add_development_dependency(%q<aruba>, ["~> 0.5.4"])
    else
      s.add_dependency(%q<middleman-core>, ["~> 3.2"])
      s.add_dependency(%q<middleman-sprockets>, ["~> 3.2"])
      s.add_dependency(%q<autoprefixer-rails>, ["~> 1.1.20140302"])
      s.add_dependency(%q<bundler>, ["~> 1.5"])
      s.add_dependency(%q<rake>, ["~> 10.1"])
      s.add_dependency(%q<middleman>, ["~> 3.2"])
      s.add_dependency(%q<cucumber>, ["~> 1.3.14"])
      s.add_dependency(%q<aruba>, ["~> 0.5.4"])
    end
  else
    s.add_dependency(%q<middleman-core>, ["~> 3.2"])
    s.add_dependency(%q<middleman-sprockets>, ["~> 3.2"])
    s.add_dependency(%q<autoprefixer-rails>, ["~> 1.1.20140302"])
    s.add_dependency(%q<bundler>, ["~> 1.5"])
    s.add_dependency(%q<rake>, ["~> 10.1"])
    s.add_dependency(%q<middleman>, ["~> 3.2"])
    s.add_dependency(%q<cucumber>, ["~> 1.3.14"])
    s.add_dependency(%q<aruba>, ["~> 0.5.4"])
  end
end
