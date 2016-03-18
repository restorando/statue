# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'statue/version'

Gem::Specification.new do |spec|
  spec.name          = "statue19"
  spec.version       = Statue::VERSION
  spec.authors       = ["Juan Barreneche"]
  spec.email         = ["devs@restorando.com"]
  spec.summary       = %q{Easily track application metrics into Statsie}
  spec.description   = %q{Track application metrics to Statsie (compat with ruby 1.9)}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
