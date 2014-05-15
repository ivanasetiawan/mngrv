# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "stylus"
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lucas Mazza"]
  s.date = "2014-02-10"
  s.description = "Bridge library to compile .styl stylesheets from ruby code."
  s.email = ["luc4smazza@gmail.com"]
  s.homepage = "https://github.com/lucasmazza/ruby-stylus"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.3"
  s.summary = "Ruby Stylus Compiler"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<execjs>, [">= 0"])
      s.add_runtime_dependency(%q<stylus-source>, [">= 0"])
    else
      s.add_dependency(%q<execjs>, [">= 0"])
      s.add_dependency(%q<stylus-source>, [">= 0"])
    end
  else
    s.add_dependency(%q<execjs>, [">= 0"])
    s.add_dependency(%q<stylus-source>, [">= 0"])
  end
end
