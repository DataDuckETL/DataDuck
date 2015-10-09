require_relative 'source.rb'

require 'sequel'

module DataDuck
  class SqlDbSource < DataDuck::Source
    def initialize(data)
      @host = data['host']
      @port = data['port']
      @username = data['username']
      @password = data['password']
      @database = data['database']
      @initialized_db_type = data['db_type']
    end

    def connection
      @connection ||= Sequel.connect(
        adapter: self.db_type,
        user: @username,
        host: @host,
        database: @database,
        password: @password,
        port: @port
      )
    end

    def db_type
      return @initialized_db_type if @initialized_db_type

      raise Exception.new("Abstract method db_type must be overwritten by subclass, or passed as data when initializing.")
    end

    def table_names
      self.connection.tables.map { |table| DataDuck::Source.skip_these_table_names.include?(table) ? nil : table }.compact
    end

    def query(sql)
      self.connection.fetch(sql).all
    end
  end
end
