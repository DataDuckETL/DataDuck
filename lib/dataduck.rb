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

  create_module_var("project_root", Dir.getwd)
  create_module_var("config", {})

  dd_env_path = DataDuck.project_root + "/config/secret/#{ ENV['DATADUCK_ENV'] }.yml"
  env_config = File.exist?(dd_env_path) ? YAML.load_file(dd_env_path) : {}
  DataDuck.config.merge!(env_config)

  create_module_var("sources", {})
  create_module_var("destinations", {})
end
