require_relative 'sql_db_source.rb'

require 'sequel'

module DataDuck
  class PostgresqlSource < DataDuck::SqlDbSource
    def db_type
      'postgres'
    end

    def dbconsole(options = {})
      args = []
      args << "--host=#{ @host }"
      args << "--username=#{ @username }"
      args << "--dbname=#{ @database }"
      args << "--port=#{ @port }"

      ENV['PGPASSWORD'] = @password

      self.find_command_and_execute("psql", *args)
    end
  end
end
