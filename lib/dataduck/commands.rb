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
      ['console', 'dbconsole', 'quickstart']
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

    def self.help
      puts "Usage: dataduck commandname"
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

      db_source = db_class.new({
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
          'my_database' => {
            'type' => db_type.to_s,
            'host' => source_host,
            'database' => source_database,
            'port' => source_port,
            'username' => source_username,
            'password' => source_password,
          }
        },
        'destinations' => {
          'my_destination' => {
            'type'  => 'redshift',
            'aws_key'  => 'YOUR_AWS_KEY',
            'aws_secret'  => 'YOUR_AWS_SECRET',
            's3_bucket'  => 'YOUR_BUCKET',
            's3_region'  => 'YOUR_BUCKET_REGION',
            'host'  => 'redshift.somekeygoeshere.us-west-2.redshift.amazonaws.com',
            'port'  => 5439,
            'database'  => 'main',
            'schema'  => 'public',
            'username'  => 'YOUR_UESRNAME',
            'password'  => 'YOUR_PASSWORD',
          }
        }
      }

      DataDuck::Commands.quickstart_save_file("#{ DataDuck.project_root }/config/secret/#{ DataDuck.environment }.yml", config_obj.to_yaml)
      DataDuck::Commands.quickstart_save_main
      DataDuck::Commands.quickstart_update_gitignore

      puts "Quickstart complete!"
      puts "You still need to edit your config/secret/*.yml file with your AWS and Redshift credentials."
      puts "Run your ETL with: ruby src/main.rb"
    end

    def self.quickstart_update_gitignore
      main_gitignore_path = "#{ DataDuck.project_root }/.gitignore"
      FileUtils.touch(main_gitignore_path)

      secret_gitignore_path = "#{ DataDuck.project_root }/config/secret/.gitignore"
      FileUtils.touch(secret_gitignore_path)
      output = File.open(secret_gitignore_path, "w")
      output << '[^.]*'
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

    def self.quickstart_save_main
      namespace = Namespace.new
      template = File.open("#{ DataDuck.gem_root }/lib/templates/quickstart/main.rb.erb", 'r').read
      result = ERB.new(template).result(namespace.get_binding)
      DataDuck::Commands.quickstart_save_file("#{ DataDuck.project_root }/src/main.rb", result)
    end
  end
end
