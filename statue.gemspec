# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'statue/version'

Gem::Specification.new do |spec|
  spec.name          = "statue"
  spec.version       = Statue::VERSION
  spec.authors       = ["Juan Barreneche"]
  spec.email         = ["devs@restorando.com"]
  spec.summary       = %q{Easily track application metrics into Statsie}
  spec.description   = %q{Track application metrics to Statsie}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rack", "~> 1.6"
  spec.add_development_dependency "rack-test", "~> 0.6.3"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "sidekiq", "~> 3.2"
  spec.add_development_dependency "pry-rescue"
  spec.add_development_dependency "pry-stack_explorer"
end
