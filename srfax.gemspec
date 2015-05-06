# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'srfax/version'

Gem::Specification.new do |spec|
  spec.name          = "srfax"
  spec.version       = Srfax::VERSION
  spec.authors       = ["Jeff Klink", "Sean Esson"]
  spec.email         = ["techcanuck@gmail.com"]

  spec.summary       = "SR Fax Module"
  spec.description   = %q{SRFax API Wrapper for Ruby: http://www.srfax.com}
  spec.homepage      = "http://rubygems.org/gems/srfax"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  
  spec.add_runtime_dependency 'logger', '~> 1'
  spec.add_runtime_dependency 'rest-client', '~> 1.7'
end
