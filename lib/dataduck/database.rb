module DataDuck
  class Database
    attr_accessor :name

    def initialize(name, *args)
      self.name = name
    end

    def connection
      raise Exception.new("Must implement connection in subclass.")
    end

    def query(sql)
      raise Exception.new("Must implement query in subclass.")
    end

    def table_names
      raise Exception.new("Must implement query in subclass.")
    end

    protected

      def load_value(prop_name, db_name, config)
        self.send("#{ prop_name }=", config[prop_name] || ENV["#{ db_name }_#{ prop_name }"])
      end

      def find_command_and_execute(commands, *args)
        # This function was originally sourced from Rails
        # https://github.com/rails/rails
        #
        # This function was licensed under the MIT license
        # http://opensource.org/licenses/MIT
        #
        # The license asks to include the following with the source code:
        #
        # Permission is hereby granted, free of charge, to any person obtaining a copy
        # of this software and associated documentation files (the "Software"), to deal
        # in the Software without restriction, including without limitation the rights
        # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        # copies of the Software, and to permit persons to whom the Software is
        # furnished to do so, subject to the following conditions:
        #
        # The above copyright notice and this permission notice shall be included in
        # all copies or substantial portions of the Software.
        #
        # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
        # THE SOFTWARE.

        commands = Array(commands)

        dirs_on_path = ENV['PATH'].to_s.split(File::PATH_SEPARATOR)

        full_path_command = nil
        found = commands.detect do |cmd|
          dirs_on_path.detect do |path|
            full_path_command = File.join(path, cmd)
            File.file?(full_path_command) && File.executable?(full_path_command)
          end
        end

        if found
          exec full_path_command, *args
        else
          abort("Couldn't find command: #{commands.join(', ')}. Check your $PATH and try again.")
        end
      end

      def is_mutating_sql?(sql)
        # This method is not all exhaustive, and is not meant to be necessarily relied on, but is a
        # sanity check that can be used to ensure certain sql is not mutating.

        return true if sql.downcase.strip.start_with?("drop table")
        return true if sql.downcase.strip.start_with?("create table")
        return true if sql.downcase.strip.start_with?("delete from")
        return true if sql.downcase.strip.start_with?("insert into")
        return true if sql.downcase.strip.start_with?("alter table")

        false
      end

  end
end
