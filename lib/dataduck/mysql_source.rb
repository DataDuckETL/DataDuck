require_relative 'sql_db_source.rb'

require 'sequel'

module DataDuck
  class MysqlSource < DataDuck::SqlDbSource
    def db_type
      'mysql'
    end

    def dbconsole(options = {})
      args = []
      args << "--host=#{ @host }"
      args << "--user=#{ @username }"
      args << "--database=#{ @database }"
      args << "--port=#{ @port }"
      args << "--password=#{ @password }"

      self.find_command_and_execute("mysql", *args)
    end
  end
end
