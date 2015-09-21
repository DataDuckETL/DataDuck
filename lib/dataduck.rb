Dir[File.dirname(__FILE__) + '/helpers/*.rb'].each do |file|
  require file
end

Dir[File.dirname(__FILE__) + '/dataduck/*.rb'].each do |file|
  require file
end

require 'yaml'

module DataDuck
  extend ModuleVars

  ENV['DATADUCK_ENV'] ||= "development"
  create_module_var("environment",  ENV['DATADUCK_ENV'])

  spec = Gem::Specification.find_by_name("dataduck")
  create_module_var("gem_root", spec.gem_dir)

  create_module_var("project_root", "/Users/jrp/projects/dd_redshift")
  create_module_var("config", {})

  env_config = YAML.load_file(DataDuck.project_root + "/config/secret/#{ ENV['DATADUCK_ENV'] }.yml")
  DataDuck.config.merge!(env_config)

  create_module_var("sources", {})
  create_module_var("destinations", {})
end
