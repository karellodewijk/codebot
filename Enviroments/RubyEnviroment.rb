require './CodeBot.rb'
require './Enviroments/Enviroment.rb'
require './Enviroments/ConsoleApplication.rb'
require './Enviroments/Task.rb'
require 'irb'
require 'tmpdir' #loads Dir.tmpdir
require 'thread'

#the ruby programming enviroment

class RubyEnviroment < Enviroment
    def initialize(task_list, command_prefix)
        super(task_list, command_prefix)
        rand(9999999999) # => 22
        @dir = Dir.tmpdir+"/"+rand.to_s+"/"
        Dir.mkdir(@dir)
    end

    def version
        return `ruby -v`
    end

    def run_code(user)
        path = @dir+"program.rb"
        f = File.open(path, 'w')
        @lines.each{|line|
            f.puts(line)
        }  
        f.close()
        #start a new task, put it in a thread and add it to the task list
        task = Task.new("#{@command_prefix} ruby #{path}", user)
        @task_list.push(task)
        @d = Thread.new {
            task.start
        }
        task.thread = @d
        @d.run()
    end

    def language
        "ruby"
    end

    def line_added(line);
        if @mode == CodeBot::INTERACTIVE

            begin
                result = @console.write(line)
                errors = @console.errors

                #parsing irb output if there is any
                if result
                    output = result.split("\n").reject{|x| x.include?(" >")} #ignore line with prompt
                    if output.size > 0
                        output = output[1..-1] #succes
                    end

                    #ruby irb prints everything to stdout, so I guess I'll be filtering is
                    newOutput = []
                    output.each {|line|
                        if /^.*?Error.*/ === line
                            puts "line: ", line
                            errors.push(line)
                        elsif  /^\tfrom.*/ === line
                            errors.push(line)
                        else
                            newOutput.push(line)
                        end
                    }
                end
                return newOutput, errors

            rescue Exception => error
                puts error
                puts error.backtrace();   
            end

        end
    end

    def mode_changed(mode)
        if @mode == CodeBot::INTERACTIVE
            puts "opening an interactive mode"
            @console = ConsoleApplication.new("irb", " >", @command_prefix)
            @console.start
        end
    end
end


