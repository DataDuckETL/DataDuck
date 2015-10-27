require_relative 'sql_db_source.rb'

require 'sequel'

module DataDuck
  class MysqlSource < DataDuck::SqlDbSource
    def db_type
      'mysql'
    end

    def dbconsole(options = {})
      args = []
      args << "--host=#{ self.host }"
      args << "--user=#{ self.username }"
      args << "--database=#{ self.database }"
      args << "--port=#{ self.port }"
      args << "--password=#{ self.password }"

      self.find_command_and_execute("mysql", *args)
    end

    def escape_char
      '`'
    end
  end
end
