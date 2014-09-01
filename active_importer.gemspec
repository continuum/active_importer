# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_importer/version'

Gem::Specification.new do |spec|
  spec.name          = "active_importer"
  spec.version       = ActiveImporter::VERSION
  spec.authors       = ["Ernesto Garcia"]
  spec.email         = ["gnapse@gmail.com"]
  spec.description   = %q{Import tabular data from spreadsheets or similar sources into data models}
  spec.summary       = %q{Import tabular data into data models}
  spec.homepage      = "http://continuum.github.io/active_importer/"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "roo"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 2.2.0"

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "activerecord"
end
