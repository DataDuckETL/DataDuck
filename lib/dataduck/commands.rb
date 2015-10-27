require 'erb'
require 'yaml'
require 'fileutils'

module DataDuck
  class Commands
    class Namespace
      def initialize(hash = {})
        hash.each do |key, value|
          singleton_class.send(:define_method, key) { value }
        end
      end

      def get_binding
        binding
      end
    end

    def self.prompt_choices(choices = [])
      while true
        print "Enter a number 0 - #{ choices.length - 1}\n"
        choices.each_with_index do |choice, idx|
          choice_name = choice.is_a?(String) ? choice : choice[1]
          print "#{ idx }: #{ choice_name }\n"
        end
        choice = STDIN.gets.strip.to_i
        if 0 <= choice && choice < choices.length
          selected = choices[choice]
          return selected.is_a?(String) ? selected : selected[0]
        end
      end
    end

    def self.acceptable_commands
      ['console', 'dbconsole', 'etl', 'quickstart', 'show']
    end

    def self.route_command(args)
      if args.length == 0
        return DataDuck::Commands.help
      end

      command = args[0]
      if !Commands.acceptable_commands.include?(command)
        puts "No such command: #{ command }"
        return DataDuck::Commands.help
      end

      DataDuck::Commands.public_send(command, *args[1..-1])
    end

    def self.console
      require "irb"
      ARGV.clear
      IRB.start
    end

    def self.dbconsole(where = "destination")
      which_database = nil
      if where == "destination"
        which_database = DataDuck::Destination.only_destination
      elsif where == "source"
        which_database = DataDuck::Source.only_source
      else
        found_source = DataDuck::Source.source(where, true)
        found_destination = DataDuck::Destination.destination(where, true)
        if found_source && found_destination
          raise ArgumentError.new("Ambiguous call to dbconsole for #{ where } since there is both a source and destination named #{ where }.")
        end

        which_database = found_source if found_source
        which_database = found_destination if found_destination
      end

      if which_database.nil?
        raise ArgumentError.new("Could not find database '#{ where }'")
      end

      puts "Connecting to #{ where }..."
      which_database.dbconsole
    end

    def self.etl(what = nil)
      if what.nil?
        puts "You need to specify a table name or 'all'. Usage: dataduck etl all OR datduck etl my_table_name"
        return
      end

      only_destination = DataDuck::Destination.only_destination

      if what == "all"
        etl = ETL.new(destinations: [only_destination], autoload_tables: true)
        etl.process!
      else
        table_name_camelized = DataDuck::Util.underscore_to_camelcase(what)
        require DataDuck.project_root + "/src/tables/#{ what }.rb"
        table_class = Object.const_get(table_name_camelized)
        if !(table_class <= DataDuck::Table)
          raise Exception.new("Table class #{ table_name_camelized } must inherit from DataDuck::Table")
        end

        table = table_class.new
        etl = ETL.new(destinations: [only_destination], autoload_tables: false, tables: [table])
        etl.process_table!(table)
      end
    end

    def self.help
      puts "Usage: dataduck commandname"
      puts "Commands: #{ acceptable_commands.sort.join(' ') }"
    end

    def self.show(table_name = nil)
      if table_name.nil?
        Dir[DataDuck.project_root + "/src/tables/*.rb"].each do |file|
          table_name_underscores = file.split("/").last.gsub(".rb", "")
          table_name_camelized = DataDuck::Util.underscore_to_camelcase(table_name_underscores)
          require file
          table = Object.const_get(table_name_camelized)
          if table <= DataDuck::Table
            puts table_name_underscores
          end
        end
      else
        table_name_camelized = DataDuck::Util.underscore_to_camelcase(table_name)
        require DataDuck.project_root + "/src/tables/#{ table_name }.rb"
        table_class = Object.const_get(table_name_camelized)
        if !(table_class <= DataDuck::Table)
          raise Exception.new("Table class #{ table_name_camelized } must inherit from DataDuck::Table")
        end

        table = table_class.new
        table.show
      end
    end

    def self.quickstart
      puts "Welcome to DataDuck!"
      puts "This quickstart wizard will help you set up DataDuck."

      puts "What kind of database would you like to source from?"
      db_type = prompt_choices([
          [:mysql, "MySQL"],
          [:postgresql, "PostgreSQL"],
          [:other, "other"],
      ])

      if db_type == :other
        puts "You've selected 'other'. Unfortunately, those are the only choices supported at the moment. Contact us at DataDuckETL.com to request support for your database."
        exit
      end

      puts "Enter the source hostname:"
      source_host = STDIN.gets.strip

      puts "Enter the name of the database when connecting to #{ source_host }:"
      source_database = STDIN.gets.strip

      puts "Enter the source's port:"
      source_port = STDIN.gets.strip.to_i

      puts "Enter the username:"
      source_username = STDIN.gets.strip

      puts "Enter the password:"
      source_password = STDIN.noecho(&:gets).chomp

      db_class = {
          mysql: DataDuck::MysqlSource,
          postgresql: DataDuck::PostgresqlSource,
      }[db_type]

      db_source = db_class.new("source1", {
          'db_type' => db_type.to_s,
          'host' => source_host,
          'database' => source_database,
          'port' => source_port,
          'username' => source_username,
          'password' => source_password,
      })

      puts "Connecting to source database..."
      table_names = db_source.table_names
      puts "Connection successful. Detected #{ table_names.length } tables."
      puts "Creating scaffolding..."
      table_names.each do |table_name|
        DataDuck::Commands.quickstart_create_table(table_name, db_source)
      end

      config_obj = {
        'sources' => {
          'source1' => {
            'type' => db_type.to_s,
            'host' => source_host,
            'database' => source_database,
            'port' => source_port,
            'username' => source_username,
          }
        },
        'destinations' => {
          'destination1' => {
            'type'  => 'redshift',
            's3_bucket'  => 'YOUR_BUCKET',
            's3_region'  => 'YOUR_BUCKET_REGION',
            'host'  => 'redshift.somekeygoeshere.us-west-2.redshift.amazonaws.com',
            'port'  => 5439,
            'database'  => 'main',
            'schema'  => 'public',
            'username'  => 'YOUR_UESRNAME',
          }
        }
      }
      DataDuck::Commands.quickstart_save_file("#{ DataDuck.project_root }/config/base.yml", config_obj.to_yaml)

      DataDuck::Commands.quickstart_save_file("#{ DataDuck.project_root }/.env", """
destination1_aws_key=AWS_KEY_GOES_HERE
destination1_aws_secret=AWS_SECRET_GOES_HERE
destination1_password=REDSHIFT_PASSWORD_GOES_HERE
source1_password=#{ source_password }
""".strip)

      DataDuck::Commands.quickstart_update_gitignore

      puts "Quickstart complete!"
      puts "You still need to edit your .env and config/base.yml files with your AWS and Redshift credentials."
      puts "Run your ETL with: dataduck etl all"
      puts "For more help, visit http://dataducketl.com/docs"
    end

    def self.quickstart_update_gitignore
      main_gitignore_path = "#{ DataDuck.project_root }/.gitignore"
      FileUtils.touch(main_gitignore_path)
      output = File.open(main_gitignore_path, "w")
      output << ".DS_Store\n"
      output << ".env\n"
      output.close
    end

    def self.quickstart_create_table(table_name, db)
      columns = []
      schema = db.schema(table_name)
      schema.each do |property_schema|
        property_name = property_schema[0]
        property_type = property_schema[1][:type]
        commented_out = ['ssn', 'socialsecurity', 'password', 'encrypted_password', 'salt', 'password_salt', 'pw'].include?(property_name.to_s.downcase)
        columns << [property_name.to_s, property_type.to_s, commented_out]
      end

      columns.sort! { |a, b| a[0] <=> b[0] }

      table_name = table_name.to_s.downcase
      table_name_camelcased = table_name.split('_').collect(&:capitalize).join
      namespace = Namespace.new(table_name_camelcased: table_name_camelcased, table_name: table_name, columns: columns)
      template = File.open("#{ DataDuck.gem_root }/lib/templates/quickstart/table.rb.erb", 'r').read
      result = ERB.new(template).result(namespace.get_binding)
      DataDuck::Commands.quickstart_save_file("#{ DataDuck.project_root }/src/tables/#{ table_name }.rb", result)
    end

    def self.quickstart_save_file(output_path_full, contents)
      *output_path, output_filename = output_path_full.split('/')
      output_path = output_path.join("/")
      FileUtils::mkdir_p(output_path)

      output = File.open(output_path_full, "w")
      output << contents
      output.close
    end
  end
end
