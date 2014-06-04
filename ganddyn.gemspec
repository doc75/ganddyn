# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ganddyn/version'

Gem::Specification.new do |spec|
  spec.name          = 'ganddyn'
  spec.version       = Ganddyn::VERSION
  spec.authors       = ['Guillaume Virlet']
  spec.email         = ['github@virlet.org']
  spec.description   = %q{This gem allows to update your GANDI DNS zone with the current external IPv4 of your machine.
It duplicate current zone information in the last inactive version of the zone (or a newly
created one if only one version exist). It updates the IPv4 for the name requested and activate
this version.}
  spec.summary       = %q{Update GANDI DNS zone IPv4}
  spec.homepage      = 'https://github.com/doc75/ganddyn'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'webmock'

  spec.add_dependency 'gandi'
  spec.add_dependency 'highline'
  spec.add_dependency 'certified'
end
