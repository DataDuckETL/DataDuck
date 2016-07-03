module DataDuck
  if !defined?(DataDuck::VERSION)
    VERSION_MAJOR = 1
    VERSION_MINOR = 0
    VERSION_PATCH = 1
    VERSION = [VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH].join('.')
  end
end
