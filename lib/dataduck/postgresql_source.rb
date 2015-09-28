require_relative 'source.rb'

require 'sequel'

module DataDuck
  class PostgresqlSource < DataDuck::Source
    def initialize(data)
      @host = data['host']
      @port = data['port']
      @username = data['username']
      @password = data['password']
      @database = data['database']
    end

    def connection
      @connection ||= Sequel.connect("postgres://#{ @username }:#{ @password }@#{ @host }:#{ @port }/#{ @database }")
    end

    def table_names
      self.connection.tables.map { |table| DataDuck::Source.skip_these_table_names.include?(table) ? nil : table }.compact
    end

    def query(sql)
      self.connection.fetch(sql).all
    end
  end
end
