require './CodeBot.rb'
require './Enviroments/Enviroment.rb'
require './Enviroments/ConsoleApplication.rb'
require './Enviroments/Task.rb'
require 'irb'
require 'tmpdir' #loads Dir.tmpdir
require 'thread'

#the java programming enviroment

class CPPEnviroment < Enviroment

    LEADING_FRAMEWORK = %q{
#include <iostream>
#include <vector>
#include <list>
#include <map>
#include <set>
#include <algorithm>
#include <queue>
#include <stack>
#include <cassert>
#include <cmath>
#include <cstdlib>
#include <sstream>

using namespace std;

int main() \{
}

    TRAILING_FRAMEWORK = %q{
    return 0;
\}
}

    def initialize(task_list, command_prefix)
        super(task_list, command_prefix)
        rand(9999999999) # => 22
        @dir = Dir.tmpdir+"/"+rand.to_s+"/"
        Dir.mkdir(@dir)
    end

    def version
        return `g++ --version`
    end

    def run_code(user)
        path = @dir+"test.cpp"
        f = File.open(path, 'w')

        if @mode !=  CodeBot::PROGRAM
            LEADING_FRAMEWORK.split("\n").each {|line|
                f.puts(line)
            }
        end

        @lines.each{|line|
            f.puts(line)
        }  

        if @mode !=  CodeBot::PROGRAM
            TRAILING_FRAMEWORK.split("\n").each {|line|
                f.puts(line)
            }
        end

        f.close()

        #start a new task and add it to the task list
        task = Task.new("cd #{@dir} && #{@command_prefix} g++ #{path} && #{@command_prefix} ./a.out", user)
        @task_list.push(task)
        @d = Thread.new {
            task.start
        }

        task.thread = @d
        @d.run()

    end

    def language
        "C"
    end

    def line_added(line);
    end

    def mode_changed(mode)
    end
end


