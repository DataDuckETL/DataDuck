require_relative 'destination.rb'

module DataDuck
  class RedshiftDestination < DataDuck::Destination
    def initialize(name, config)
      @aws_key = config['aws_key']
      @aws_secret = config['aws_secret']
      @s3_bucket = config['s3_bucket']
      @s3_region = config['s3_region']
      @host = config['host']
      @port = config['port']
      @database = config['database']
      @schema = config['schema']
      @username = config['username']
      @password = config['password']
      @redshift_connection = nil

      super
    end

    def connection
      @redshift_connection ||= Sequel.connect("redshift://#{ @username }:#{ @password }@#{ @host }:#{ @port }/#{ @database }" +
              "?force_standard_strings=f",
          :client_min_messages => '',
          :force_standard_strings => false
      )
    end

    def copy_query(table, s3_path)
      properties_joined_string = "\"#{ table.output_column_names.join('","') }\""
      query_fragments = []
      query_fragments << "COPY #{ self.staging_table_name(table) } (#{ properties_joined_string })"
      query_fragments << "FROM '#{ s3_path }'"
      query_fragments << "CREDENTIALS 'aws_access_key_id=#{ @aws_key };aws_secret_access_key=#{ @aws_secret }'"
      query_fragments << "REGION '#{ @s3_region }'"
      query_fragments << "CSV TRUNCATECOLUMNS ACCEPTINVCHARS EMPTYASNULL"
      query_fragments << "DATEFORMAT 'auto'"
      return query_fragments.join(" ")
    end

    def create_columns_on_data_warehouse!(table)
      columns = get_columns_in_data_warehouse(table)
      column_names = columns.map { |col| col[:name].to_s }
      table.output_schema.map do |name, data_type|
        if !column_names.include?(name.to_s)
          redshift_data_type = data_type.to_s
          redshift_data_type = 'varchar(255)' if redshift_data_type == 'string'
          self.run_query("ALTER TABLE #{ table.name } ADD #{ name } #{ redshift_data_type }")
        end
      end
    end

    def create_table_query(table, table_name = nil)
      table_name ||= table.name
      props_array = table.output_schema.map do |name, data_type|
        redshift_data_type = data_type.to_s
        redshift_data_type = 'varchar(255)' if redshift_data_type == 'string'
        "\"#{ name }\" #{ redshift_data_type }"
      end
      props_string = props_array.join(', ')

      distribution_clause = table.distribution_key ? "DISTKEY(#{ table.distribution_key })" : ""
      index_clause = table.indexes.length > 0 ? "INTERLEAVED SORTKEY (#{ table.indexes.join(',') })" : ""

      "CREATE TABLE IF NOT EXISTS #{ table_name } (#{ props_string }) #{ distribution_clause } #{ index_clause }"
    end

    def create_output_table_on_data_warehouse!(table)
      self.run_query(self.create_table_query(table))
      self.create_columns_on_data_warehouse!(table)
    end

    def create_staging_table!(table)
      table_name = self.staging_table_name(table)
      self.drop_staging_table!(table)
      self.run_query(self.create_table_query(table, table_name))
    end

    def data_as_csv_string(data, property_names)
      data_string_components = [] # for performance reasons, join strings this way
      data.each do |result|
        property_names.each_with_index do |property_name, index|
          value = result[property_name.to_sym]

          if index == 0
            data_string_components << '"'
          end

          data_string_components << DataDuck::RedshiftDestination.value_to_string(value)

          if index == property_names.length - 1
            data_string_components << '"'
          else
            data_string_components << '","'
          end
        end
        data_string_components << "\n"
      end

      return data_string_components.join
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

    def drop_staging_table!(table)
      self.run_query("DROP TABLE IF EXISTS #{ self.staging_table_name(table) }")
    end

    def get_columns_in_data_warehouse(table)
      query = "SELECT pg_table_def.column as name, type as data_type, distkey, sortkey FROM pg_table_def WHERE tablename='#{ table.name }'"
      results = self.run_query(query)

      columns = []
      results.each do |result|
        columns << {
            name: result[:name],
            data_type: result[:data_type],
            distkey: result[:distkey],
            sortkey: result[:sortkey]
        }
      end

      return columns
    end

    def merge_from_staging!(table)
      # Following guidelines in http://docs.aws.amazon.com/redshift/latest/dg/merge-examples.html
      staging_name = self.staging_table_name(table)
      delete_query = "DELETE FROM #{ table.name } USING #{ staging_name } WHERE #{ table.name }.id = #{ staging_name }.id" # TODO allow custom or multiple keys
      self.run_query(delete_query)
      insert_query = "INSERT INTO #{ table.name } (\"#{ table.output_column_names.join('","') }\") SELECT \"#{ table.output_column_names.join('","') }\" FROM #{ staging_name }"
      self.run_query(insert_query)
    end

    def run_query(sql)
      self.connection[sql].map { |elem| elem }
    end

    def staging_table_name(table)
      "zz_dataduck_#{ table.name }"
    end

    def upload_table_to_s3!(table)
      now_epoch = Time.now.to_i.to_s
      filepath = "pending/#{ table.name.downcase }_#{ now_epoch }.csv"

      table_csv = self.data_as_csv_string(table.data, table.output_column_names)

      s3_obj = S3Object.new(filepath, table_csv, @aws_key, @aws_secret,
          @s3_bucket, @s3_region)
      s3_obj.upload!
      return s3_obj
    end

    def load_table!(table)
      DataDuck::Logs.info "Loading table #{ table.name }..."
      s3_object = self.upload_table_to_s3!(table)
      self.create_staging_table!(table)
      self.create_output_table_on_data_warehouse!(table)
      self.run_query(self.copy_query(table, s3_object.s3_path))
      self.merge_from_staging!(table)
      self.drop_staging_table!(table)
    end

    def self.value_to_string(value)
      string_value = ''
      if value.respond_to? :to_s
        string_value = value.to_s
      end
      string_value.gsub!('"', '""')
      return string_value
    end
  end
end
