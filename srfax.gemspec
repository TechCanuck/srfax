# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'sr_fax'
  spec.version       = SrFax::VERSION
  spec.authors       = ['Jeff Klink', 'Sean Esson']
  spec.email         = ['techcanuck@gmail.com']

  spec.summary       = 'SR Fax Module provides and easy way to access SR fax online services to send, receive or query faxes'
  spec.description   = "This is the 'unofficial' SRFax (http://www.srfax.com) API wrapper for ruby.  The API documentation for SRFax can be found at https://www.srfax.com/srf/media/SRFax-REST-API-Documentation.pdf"
  spec.homepage      = 'https://github.com/TechCanuck/srfax'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'pry', '~> 0.8'
  spec.add_development_dependency 'yard', '~> 0.8'
  spec.add_dependency 'logger', '~> 1'
  spec.add_dependency 'oj', '~> 2.11'
  spec.add_dependency 'activesupport', '~> 4.2'
  spec.add_dependency 'rest-client', '~> 1.7'
end
