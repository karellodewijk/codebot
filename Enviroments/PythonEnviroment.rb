require './CodeBot.rb'
require './Enviroments/Enviroment.rb'
require './Enviroments/ConsoleApplication'
require 'irb'
require 'tmpdir' #loads Dir.tmpdir

#the ruby programming enviroment

class PythonEnviroment < Enviroment
    def initialize(task_list)
        super(task_list)
    end

    def version
        return `python -v`
    end

    def run_code(user)
        path = @dir+"program.py"
        f = File.open(path, 'w')
        @lines.each{|line|
            f.puts(line)
        }  
        f.close()

        #start a new task and add it to the task list
        task = Task.new("python #{path}", user)
        @task_list.push(task)
        @d = Thread.new {
            task.start
        }
        task.thread = @d  
        @d.run()
    end

    def language
        "python"
    end

    
    def line_added(line);

        if @mode == CodeBot::INTERACTIVE

            #following code is keep bufferin a line that ends with: until the number of : is matched by the number of newlines (like python console)
            if line.include? "#"
                line = line.split("#")[0]
            end
            line.rstrip!

            print "line: ", line, "\n"

            if line[-1] == ":"
                puts "start buffering"
                @buffer = @buffer ? @buffer+line+"\n" : line+"\n"
                return
            end
            if @buffer
                puts "buffer not empty", line
                if line.strip != "" #cont buffering
                    puts "cont buffering"
                    @buffer += line+"\n"
                    return
                else
                    line = @buffer
                end
            end
            #end

            result = @console.write(line)
            errors = @console.errors

            output = result.split("\n").reject{|x| x.include?("$>")} #ignore line with prompt
            return output, error
        end
    end

    def mode_changed(mode)
        if @mode == CodeBot::INTERACTIVE
            puts "opening an interactive python mode"
            @console = ConsoleApplication.new("python ./Enviroments/console.py", "$>")
            puts @console.start
        end
    end
end


