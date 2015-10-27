require_relative 'sql_db_source.rb'

require 'sequel'

module DataDuck
  class PostgresqlSource < DataDuck::SqlDbSource
    def db_type
      'postgres'
    end

    def dbconsole(options = {})
      args = []
      args << "--host=#{ self.host }"
      args << "--username=#{ self.username }"
      args << "--dbname=#{ self.database }"
      args << "--port=#{ self.port }"

      ENV['PGPASSWORD'] = self.password

      self.find_command_and_execute("psql", *args)
    end

    def data_size_for_table(table_name)
      size_in_bytes = self.query("SELECT pg_total_relation_size('#{ table_name }')").first.to_i
      size_in_gb = size_in_bytes / 1_000_000_000.0
      size_in_gb
    end

    def escape_char
      '"'
    end
  end
end
