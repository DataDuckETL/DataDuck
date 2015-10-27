require 'dotenv'
Dotenv.load

require 'yaml'

Dir[File.dirname(__FILE__) + '/helpers/*.rb'].each do |file|
  require file
end

Dir[File.dirname(__FILE__) + '/dataduck/*.rb'].each do |file|
  require file
end

module DataDuck
  extend ModuleVars

  ENV['DATADUCK_ENV'] ||= "development"
  create_module_var("environment", ENV['DATADUCK_ENV'])

  spec = Gem::Specification.find_by_name("dataduck")
  create_module_var("gem_root", spec.gem_dir)

  detect_project_root = Dir.getwd
  while true
    if detect_project_root == ""
      raise Exception.new("Could not find a Gemfile in the current working directory or any parent directories. Are you sure you're running this from the right place?")
    end

    if File.exist?(detect_project_root + '/Gemfile')
      break
    end

    detect_project_root_splits = detect_project_root.split("/")
    detect_project_root_splits = detect_project_root_splits[0..detect_project_root_splits.length - 2]
    detect_project_root = detect_project_root_splits.join("/")
  end
  create_module_var("project_root", detect_project_root)

  create_module_var("config", {})
  configs_to_load = ["/config/base.yml", "/config/#{ ENV['DATADUCK_ENV'] }.yml",
    "/config/secret/base.yml", "/config/secret/#{ ENV['DATADUCK_ENV'] }.yml"]
  configs_to_load.each do |relative_path|
    config_path = DataDuck.project_root + relative_path
    loaded_config = File.exist?(config_path) ? YAML.load_file(config_path) : {}
    DataDuck.config = Util.deep_merge(DataDuck.config, loaded_config)
  end

  create_module_var("sources", {})
  create_module_var("destinations", {})

  DataDuck::Source.load_config!
  DataDuck::Destination.load_config!

  Dir[DataDuck.project_root + "/src/tables/*.rb"].each do |file|
    table_name_underscores = file.split("/").last.gsub(".rb", "")
    table_name_camelized = DataDuck::Util.underscore_to_camelcase(table_name_underscores)
    require file
  end
end
