require 'fileutils'

module DataDuck
  module Util
    def Util.deep_merge(first, second)
      merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
      first.merge(second, &merger)
    end

    def Util.ensure_path_exists!(full_path)
      split_paths = full_path.split('/')
      just_file_path = split_paths.pop
      directory_path = split_paths.join('/')
      FileUtils.mkdir_p(directory_path)
      FileUtils.touch("#{ directory_path }/#{ just_file_path }")
    end

    def Util.underscore_to_camelcase(str)
      str.split('_').map{ |chunk| chunk.capitalize }.join
    end

    def Util.camelcase_to_underscore(str)
      str.gsub(/::/, '/')
          .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
          .gsub(/([a-z\d])([A-Z])/,'\1_\2')
          .tr("-", "_")
          .downcase
    end
  end
end
