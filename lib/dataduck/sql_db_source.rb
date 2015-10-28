require_relative 'source'
require_relative 'logs'

require 'sequel'

module DataDuck
  class SqlDbSource < DataDuck::Source
    attr_accessor :host
    attr_accessor :port
    attr_accessor :username
    attr_accessor :password
    attr_accessor :database

    def initialize(name, config)
      load_value('host', name, config)
      load_value('port', name, config)
      load_value('username', name, config)
      load_value('password', name, config)
      load_value('database', name, config)

      @initialized_db_type = config['db_type']

      super
    end

    def connection
      adapter = self.db_type.to_s
      adapter = 'mysql2' if adapter == 'mysql' # mysql2 adapter is faster than just mysql

      @connection ||= Sequel.connect(
        adapter: adapter,
        user: self.username,
        host: self.host,
        database: self.database,
        password: self.password,
        port: self.port
      )
    end

    def db_type
      return @initialized_db_type if @initialized_db_type

      raise NotImplementedError.new("Abstract method db_type must be overwritten by subclass, or passed as data when initializing.")
    end

    def escape_char
      raise NotImplementedError.new("Abstract method escape_char must be overwritten by subclass.")
    end

    def table_names
      self.connection.tables.map { |table| DataDuck::Source.skip_these_table_names.include?(table) ? nil : table }.compact
    end

    def query(sql)
      if self.is_mutating_sql?(sql)
        raise ArgumentError.new("Database #{ self.name } must not run mutating sql: #{ sql }")
      end

      Logs.debug("SQL executing on #{ self.name }:\n  " + sql)
      self.connection.fetch(sql).all
    end
  end
end
