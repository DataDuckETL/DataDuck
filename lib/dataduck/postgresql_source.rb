require_relative 'sql_db_source.rb'

require 'sequel'

module DataDuck
  class PostgresqlSource < DataDuck::SqlDbSource
    def db_type
      'postgres'
    end
  end
end
