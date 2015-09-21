module DataDuck
  class Commands
    def self.acceptable_commands
      ['quickstart']
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

      DataDuck::Commands.public_send(command)
    end

    def self.help
      puts "Usage: dataduck commandname"
    end

    def self.quickstart
      puts "Welcome to DataDuck!"
    end
  end
end
