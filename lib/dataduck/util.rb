module DataDuck
  class Util
    def self.underscore_to_camelcase(str)
      str.split('_').map{ |chunk| chunk.capitalize }.join
    end

    def self.camelcase_to_underscore(str)
      str.gsub(/::/, '/')
          .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
          .gsub(/([a-z\d])([A-Z])/,'\1_\2')
          .tr("-", "_")
          .downcase
    end
  end
end
