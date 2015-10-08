require 'rubygems'
require 'bundler/setup'
Bundler.require

require_relative "tables/games"
require_relative "tables/users"

class MyCompanyETL < DataDuck::ETL
  destination :main_destination
end

etl = MyCompanyETL.new
etl.process!
