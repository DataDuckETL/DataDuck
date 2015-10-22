require_relative 'destination'

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
      query_fragments << "COPY #{ table.staging_name } (#{ properties_joined_string })"
      query_fragments << "FROM '#{ s3_path }'"
      query_fragments << "CREDENTIALS 'aws_access_key_id=#{ @aws_key };aws_secret_access_key=#{ @aws_secret }'"
      query_fragments << "REGION '#{ @s3_region }'"
      query_fragments << "CSV TRUNCATECOLUMNS ACCEPTINVCHARS EMPTYASNULL"
      query_fragments << "DATEFORMAT 'auto'"
      return query_fragments.join(" ")
    end

    def create_columns_on_data_warehouse!(table)
      columns = get_columns_in_data_warehouse(table.building_name)
      column_names = columns.map { |col| col[:name].to_s }
      table.output_schema.map do |name, data_type|
        if !column_names.include?(name.to_s)
          redshift_data_type = self.type_to_redshift_type(data_type)
          self.query("ALTER TABLE #{ table.building_name } ADD #{ name } #{ redshift_data_type }")
        end
      end
    end

    def create_table_query(table, table_name = nil)
      table_name ||= table.name
      props_array = table.output_schema.map do |name, data_type|
        redshift_data_type = self.type_to_redshift_type(data_type)
        "\"#{ name }\" #{ redshift_data_type }"
      end
      props_string = props_array.join(', ')

      distribution_clause = table.distribution_key ? "DISTKEY(#{ table.distribution_key })" : ""
      index_clause = table.indexes.length > 0 ? "INTERLEAVED SORTKEY (#{ table.indexes.join(',') })" : ""

      "CREATE TABLE IF NOT EXISTS #{ table_name } (#{ props_string }) #{ distribution_clause } #{ index_clause }"
    end

    def create_output_tables!(table)
      self.query(self.create_table_query(table, table.building_name))
      self.create_columns_on_data_warehouse!(table)

      if table.building_name != table.staging_name
        self.drop_staging_table!(table)
        self.query(self.create_table_query(table, table.staging_name))
      end
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

    def type_to_redshift_type(which_type)
      which_type = which_type.to_s

      if ["string", "text", "bigtext"].include?(which_type)
        {
            "string" => "varchar(255)",
            "text" => "varchar(8191)",
            "bigtext" => "varchar(65535)", # Redshift maximum
        }[which_type]
      else
        which_type
      end
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
      self.query("DROP TABLE IF EXISTS #{ table.staging_name }")
    end

    def get_columns_in_data_warehouse(table_name)
      cols_query = "SELECT pg_table_def.column AS name, type AS data_type, distkey, sortkey FROM pg_table_def WHERE tablename='#{ table_name }'"
      results = self.query(cols_query)

      columns = []
      results.each do |result|
        columns << {
            name: result[:name],
            data_type: result[:data_type],
            distkey: result[:distkey],
            sortkey: result[:sortkey],
        }
      end

      return columns
    end

    def merge_from_staging!(table)
      if table.staging_name == table.building_name
        return
      end

      # Following guidelines in http://docs.aws.amazon.com/redshift/latest/dg/merge-examples.html
      staging_name = table.staging_name
      building_name = table.building_name
      delete_query = "DELETE FROM #{ building_name } USING #{ staging_name } WHERE #{ building_name }.id = #{ staging_name }.id" # TODO allow custom or multiple keys
      self.query(delete_query)
      insert_query = "INSERT INTO #{ building_name } (\"#{ table.output_column_names.join('","') }\") SELECT \"#{ table.output_column_names.join('","') }\" FROM #{ staging_name }"
      self.query(insert_query)
    end

    def query(sql)
      Logs.debug("SQL executing on #{ self.name }:\n  " + sql)
      self.connection[sql].map { |elem| elem }
    end

    def table_names
      self.query("SELECT DISTINCT(tablename) AS name FROM pg_table_def WHERE schemaname='public' ORDER BY name").map { |item| item[:name] }
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

    def finish_fully_reloading_table!(table)
      self.query("DROP TABLE IF EXISTS zz_dataduck_old_#{ table.name }")

      table_already_exists = self.table_names.include?(table.name)
      if table_already_exists
        self.query("ALTER TABLE #{ table.name } RENAME TO zz_dataduck_old_#{ table.name }")
      end

      self.query("ALTER TABLE #{ table.staging_name } RENAME TO #{ table.name }")
      self.query("DROP TABLE IF EXISTS zz_dataduck_old_#{ table.name }")
    end

    def load_table!(table)
      DataDuck::Logs.info "Loading table #{ table.name }..."
      s3_object = self.upload_table_to_s3!(table)
      self.create_output_tables!(table)
      self.query(self.copy_query(table, s3_object.s3_path))

      if table.staging_name != table.building_name
        self.merge_from_staging!(table)
        self.drop_staging_table!(table)
      end
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
