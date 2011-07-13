require './CodeBot.rb'
require './Enviroments/Enviroment.rb'
require './Enviroments/ConsoleApplication.rb'
require './Enviroments/Task.rb'
require 'irb'
require 'tmpdir' #loads Dir.tmpdir
require 'thread'

#the java programming enviroment

class JavaEnviroment < Enviroment

    LEADING_FRAMEWORK = %q{
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.util.*;
import java.io.*;
import java.text.*;
import java.util.regex.*;
class Test \{
    public static void main(String[] args) \{
}

    TRAILING_FRAMEWORK = %q{
    \}
\}
}

    def initialize(task_list)
        super(task_list)
        rand(9999999999) # => 22
        @dir = Dir.tmpdir+"/"+rand.to_s+"/"
        Dir.mkdir(@dir)
    end

    def version
        return `java -version`
    end

    def run_code(user)
        path = @dir+"Test.java"
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
        task = Task.new("cd #{@dir} && javac #{path} && java Test ", user)
        @task_list.push(task)
        @d = Thread.new {
            task.start
        }

        task.thread = @d
        @d.run()

    end

    def language
        "java"
    end

    def line_added(line);
    end

    def mode_changed(mode)
    end
end


