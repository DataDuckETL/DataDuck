# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dataduck/version'

Gem::Specification.new do |spec|
  spec.authors = ["Jeff Pickhardt"]
  spec.description = "A straightforward, effective ETL framework."
  spec.email = ["pickhardt@gmail.com", "admin@dataducketl.com"]
  spec.executables = ["dataduck"]
  spec.homepage = "http://dataducketl.com/"
  spec.name = "dataduck"
  spec.summary = "A straightforward, effective ETL framework."
  spec.version = DataDuck::VERSION

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir = "bin"
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"

  spec.add_runtime_dependency "dotenv", '~> 2.0'
  spec.add_runtime_dependency "sequel", '~> 4.19'
  spec.add_runtime_dependency "pg", '~> 0.16'
  spec.add_runtime_dependency "mysql", "~> 2.9"
  spec.add_runtime_dependency "aws-sdk", "~> 2.0"
  spec.add_runtime_dependency "sequel-redshift"
end
