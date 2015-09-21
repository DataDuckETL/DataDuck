# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dataduck/version'

Gem::Specification.new do |spec|
  spec.name = "dataduck"
  spec.version = DataDuck::VERSION
  spec.authors = ["Jeff Pickhardt"]
  spec.email = ["pickhardt@gmail.com"]

  spec.summary = "DataDuck is an ETL framework."
  spec.description = "DataDuck is a comprehensive ETL framework."
  spec.homepage = "http://dataducketl.com/"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir = "bin"
  spec.executables = ["dataduck"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_runtime_dependency "sequel", '~> 4.19.0'
  spec.add_runtime_dependency "pg", '~> 0.16.0'
  spec.add_runtime_dependency "aws-sdk", "~> 2.0.42"
  spec.add_runtime_dependency "sequel-redshift"
end
