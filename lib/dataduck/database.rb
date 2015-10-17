module DataDuck
  class Database
    attr_accessor :name

    def initialize(name, *args)
      self.name = name
    end

    protected
      def find_command_and_execute(commands, *args)
        # This function was originally sourced from Rails
        # https://github.com/rails/rails
        #
        # Licensed under the MIT license
        # http://opensource.org/licenses/MIT
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
  end
end
