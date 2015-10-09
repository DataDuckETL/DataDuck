require_relative 'sql_db_source.rb'

require 'sequel'

module DataDuck
  class MysqlSource < DataDuck::SqlDbSource
    def db_type
      'mysql'
    end
  end
end
