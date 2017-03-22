require_relative 'destination'

module DataDuck
  class RedshiftLoadError < StandardError; end

  class RedshiftDestination < DataDuck::Destination
    attr_accessor :aws_key
    attr_accessor :aws_secret
    attr_accessor :s3_bucket
    attr_accessor :s3_region
    attr_accessor :host
    attr_accessor :port
    attr_accessor :database
    attr_accessor :schema
    attr_accessor :username
    attr_accessor :password

    def initialize(name, config)
      load_value('aws_key', name, config)
      load_value('aws_secret', name, config)
      load_value('s3_bucket', name, config)
      load_value('s3_region', name, config)
      load_value('host', name, config)
      load_value('port', name, config)
      load_value('database', name, config)
      load_value('schema', name, config)
      load_value('username', name, config)
      load_value('password', name, config)

      @redshift_connection = nil

      super
    end

    def connection
      @redshift_connection ||= Sequel.connect("redshift://#{ self.username }:#{ self.password }@#{ self.host }:#{ self.port }/#{ self.database }" +
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
      query_fragments << "CREDENTIALS 'aws_access_key_id=#{ self.aws_key };aws_secret_access_key=#{ self.aws_secret }'"
      query_fragments << "REGION '#{ self.s3_region }'"
      query_fragments << "CSV IGNOREHEADER 1 TRUNCATECOLUMNS ACCEPTINVCHARS EMPTYASNULL"
      query_fragments << "DATEFORMAT 'auto' GZIP"
      return query_fragments.join(" ")
    end

    def create_columns_on_data_warehouse!(table)
      columns = get_columns_in_data_warehouse(table.building_name)
      column_names = columns.map { |col| col[:name].to_s }
      table.create_schema.map do |name, data_type|
        if !column_names.include?(name.to_s)
          redshift_data_type = self.type_to_redshift_type(data_type)
          self.query("ALTER TABLE #{ table.building_name } ADD #{ name } #{ redshift_data_type }")
        end
      end
    end

    def create_table_query(table, table_name = nil)
      table_name ||= table.name
      props_array = table.create_schema.map do |name, data_type|
        redshift_data_type = self.type_to_redshift_type(data_type)
        "\"#{ name }\" #{ redshift_data_type }"
      end
      props_string = props_array.join(', ')

      distribution_clause = table.distribution_key ? "DISTKEY(#{ table.distribution_key })" : ""
      distribution_style_clause = table.distribution_style ? "DISTSTYLE #{ table.distribution_style }" : ""
      index_clause = table.indexes.length > 0 ? "INTERLEAVED SORTKEY (#{ table.indexes.join(',') })" : ""

      "CREATE TABLE IF NOT EXISTS #{ table_name } (#{ props_string }) #{ distribution_clause } #{ distribution_style_clause } #{ index_clause }"
    end

    def create_output_tables!(table)
      self.create_output_table_with_name!(table, table.building_name)
      self.create_columns_on_data_warehouse!(table)

      if table.building_name != table.staging_name
        self.drop_staging_table!(table)
        self.create_output_table_with_name!(table, table.staging_name)
      end
    end

    def create_output_table_with_name!(table, name)
      self.query(self.create_table_query(table, name))
    end

    def data_as_csv_string(data, property_names)
      data_string_components = [] # join strings this way for now, could be optimized later

      data_string_components << property_names.join(',') # header column
      data_string_components << "\n"

      data.each do |result|
        property_names.each_with_index do |property_name, index|
          value = result[property_name.to_sym]
          if value.nil?
            value = result[property_name.to_s]
          end

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
      args << "--host=#{ self.host }"
      args << "--username=#{ self.username }"
      args << "--dbname=#{ self.database }"
      args << "--port=#{ self.port }"

      ENV['PGPASSWORD'] = self.password

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
      self.delete_before_inserting!(table)
      self.insert_from_staging!(table)
    end

    def delete_before_inserting!(table)
      staging_name = table.staging_name
      building_name = table.building_name

      where_equals_parts = []
      table.identify_by_columns.each do |attribute|
        where_equals_parts << "#{ building_name }.#{ attribute } = #{ staging_name }.#{ attribute }"
      end

      delete_query = "DELETE FROM #{ building_name } USING #{ staging_name } WHERE #{ where_equals_parts.join(' AND ') }"
      self.query(delete_query)
    end

    def insert_from_staging!(table)
      staging_name = table.staging_name
      building_name = table.building_name
      insert_query = "INSERT INTO #{ building_name } (\"#{ table.output_column_names.join('","') }\") SELECT \"#{ table.output_column_names.join('","') }\" FROM #{ staging_name }"
      self.query(insert_query)
    end

    def query(sql)
      Logs.debug("SQL executing on #{ self.name }:\n  " + sql)
      begin
        self.connection[sql].map { |elem| elem }
      rescue => err
        if err.to_s.include?("Check 'stl_load_errors' system table for details")
          self.raise_stl_load_error!
        else
          raise err
        end
      end
    end

    def raise_stl_load_error!
      load_error_sql = "SELECT filename, line_number, colname, position, err_code, err_reason FROM stl_load_errors ORDER BY starttime DESC LIMIT 1"
      load_error_details = self.connection[load_error_sql].map { |elem| elem }.first

      raise RedshiftLoadError.new("Error loading Redshift, '#{ load_error_details[:err_reason].strip }' " +
          "(code #{ load_error_details[:err_code] }) with file #{ load_error_details[:filename].strip } " +
          "for column '#{ load_error_details[:colname].strip }'. The error occurred at line #{ load_error_details[:line_number] }, position #{ load_error_details[:position] }.")
    end

    def table_names
      self.query("SELECT DISTINCT(tablename) AS name FROM pg_table_def WHERE schemaname='public' ORDER BY name").map { |item| item[:name] }
    end

    def gzip(data)
      sio = StringIO.new
      gz = Zlib::GzipWriter.new(sio)
      gz.write(data)
      gz.close
      sio.string
    end

    def upload_table_to_s3!(table)
      now_epoch = Time.now.to_i.to_s
      filepath = "pending/#{ table.name.downcase }_#{ now_epoch }.csv.gz"

      table_csv = self.gzip(self.data_as_csv_string(table.data, table.output_column_names))

      s3_obj = S3Object.new(filepath, table_csv, self.aws_key, self.aws_secret,
          self.s3_bucket, self.s3_region)
      s3_obj.upload!
      s3_obj
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
      query_to_run = self.copy_query(table, s3_object.s3_path)
      self.query(query_to_run)
      s3_object.delete!

      if table.staging_name != table.building_name
        self.merge_from_staging!(table)
        self.drop_staging_table!(table)
      end
    end

    def recreate_table!(table)
      DataDuck::Logs.info "Recreating table #{ table.name }..."

      if !self.table_names.include?(table.name)
        raise "Table #{ table.name } doesn't exist on the Redshift database, so it can't be recreated. Did you want to use `dataduck create #{ table.name }` instead?"
      end

      recreating_temp_name = "zz_dataduck_recreating_#{ table.name }"
      self.create_output_table_with_name!(table, recreating_temp_name)
      self.query("INSERT INTO #{ recreating_temp_name } (\"#{ table.create_column_names.join('","') }\") SELECT \"#{ table.create_column_names.join('","') }\" FROM #{ table.name }")
      self.query("ALTER TABLE #{ table.name } RENAME TO zz_dataduck_recreating_old_#{ table.name }")
      self.query("ALTER TABLE #{ recreating_temp_name } RENAME TO #{ table.name }")
      self.query("DROP TABLE zz_dataduck_recreating_old_#{ table.name }")
    end

    def postprocess!(table)
      DataDuck::Logs.info "Vacuuming table #{ table.name }"
      vacuum_type = table.indexes.length == 0 ? "FULL" : "REINDEX"
      self.query("VACUUM #{ vacuum_type } #{ table.name }")
    end

    def self.value_to_string(value)
      string_value = ''

      if value.respond_to?(:strftime)
        from_value = value.respond_to?(:utc) ? value.utc : value
        string_value =  from_value.strftime('%Y-%m-%d %H:%M:%S')
      elsif value.respond_to?(:to_s)
        string_value = value.to_s
      end

      string_value.gsub!('"', '""')

      return string_value
    end
  end
end
