module DataDuck
  class Destination < DataDuck::Database
    def self.load_config!
      all_config = DataDuck.config['destinations']
      return if all_config.nil?

      all_config.each_key do |destination_name|
        configuration = all_config[destination_name]
        destination_type = configuration['type']

        if destination_type == "redshift"
          DataDuck.destinations[destination_name] = DataDuck::RedshiftDestination.new(configuration)
        else
          raise ArgumentError.new("Unknown type '#{ destination_type }' for destination #{ destination_name }.")
        end
      end
    end

    def self.destination_config(name)
      if DataDuck.config['destinations'].nil? || DataDuck.config['destinations'][name.to_s].nil?
        raise Exception.new("Could not find destination #{ name } in destinations configs.")
      end

      DataDuck.config['destinations'][name.to_s]
    end

    def load_table!(table)
      raise Exception.new("Must implement load_table! in subclass")
    end

    def self.destination(name, allow_nil = false)
      name = name.to_s

      if DataDuck.destinations[name]
        return DataDuck.destinations[name]
      elsif allow_nil
        return nil
      else
        raise Exception.new("Could not find destination #{ name } in destination configs.")
      end
    end

    def self.only_destination
      if DataDuck.destinations.keys.length != 1
        raise ArgumentError.new("Must be exactly 1 destination.")
      end

      destination_name = DataDuck.destinations.keys[0]
      return DataDuck::Destination.destination(destination_name)
    end
  end
end
