require './IrcClient'
require './Enviroments/RubyEnviroment.rb'
require './Enviroments/PythonEnviroment.rb'
require './Enviroments/JavaEnviroment.rb'
require './Enviroments/CEnviroment.rb'
require './Enviroments/CPPEnviroment.rb'
require 'time'

class CodeBot < IrcClient
    Mode = [INTERACTIVE = 'INTERACTIVE', SNIPPET = 'SNIPPET', PROGRAM = 'PROGRAM']
    Language = [RUBY = 'RUBY', PYTHON = 'PYTHON', JAVA = 'JAVA', C = 'C', CPP = 'C++']

    #list of running tasks
    @tasks = []
    #map of enviroments {user -> Enviroment}
    @active_user_enviroments = {}

    def initialize(server, channel, port)
        super(server, port, channel, "cbot", "A bot that can quickly compile/run code snippets in various programming languages")
        @active_user_enviroments = {}
        @tasks = []
    end

  private

    def tick
        now = Time.now()
        @tasks.reject!{|task|
            if task.done()
                send_to_user(task.user, task.errors)
                send(task.result)
                true
            else
                false
            end
        }
    end
    
    def user_left(user) 
        @active_user_enviroments.delete(user)
    end

    def parse_new(user, splitRequest)
        if splitRequest.size >= 1
            language = splitRequest[0].upcase
            if !Language.include? language
                send("unknown programming language #{language}, choose from (ruby, java, python, c, c++)")
                return
            end

            mode = INTERACTIVE
            if splitRequest.size >= 2
                modeStr = splitRequest[1].upcase
                case modeStr #parses shorthand version
                    when "I"
                        modeStr = INTERACTIVE
                    when "S"
                        modeStr = SNIPPET
                    when "P"
                        modeStr = PROGRAM
                end

                if !Mode.include? modeStr
                    send("unknown mode #{mode}, choose from (interactive, snippet, program)")
                    return
                else
                    mode = modeStr
                end
            end

            case language
                when RUBY        
                    @active_user_enviroments[user] = RubyEnviroment.new(@tasks)
                when PYTHON
                    @active_user_enviroments[user] = PythonEnviroment.new(@tasks)
                when JAVA
                    @active_user_enviroments[user] = JavaEnviroment.new(@tasks)
                when C
                    @active_user_enviroments[user] = CEnviroment.new(@tasks)
                when CPP
                    @active_user_enviroments[user] = CPPEnviroment.new(@tasks)
            else
                send("#{language} language currently not supported")
                return                
            end
            change_nick("#{@base_nick}[#{language[0..3]}|#{mode[0]}]");
            @active_user_enviroments[user].mode = mode

        else
            send("usage: #{@nick} new language (interactive|snippet|program)")
            return
        end
    end

    def parse_request(user, splitRequest)
        if splitRequest.size > 0
            case splitRequest[0]
                when "new","n"
                    parse_new(user, splitRequest[1..-1])
                    return
                when "help"
help_message = %q{
Cbot is an interactive programming enviroment in irc, say cbot info for more info:
----------------------------------------------------------------------------------
 
list of commands:
 
All commands must be prefixed by cbot. parameters between () are optional. | signifies or. 
 
new|n (ruby|python|java|c|c++) (i|s|p)      Start program enviroment in interactive|snippet|program mode
stop|s                                      Stop program enviroment, progress will be lost
run|r                                       Run program or snippet
delete|d|undo|u (nothing|line|start stop)   Delete last line|given line|range
add|a user                                  Add another user to your programming enviroment
pause|wait|w                                Stop adding lines but do not stop programming enviroment
continue|cont|c                             Continue when paused
print|progress|p (nothing|line|start stop)  Print all|line|range
edit|e|change index newline                 Changes line index with newline
insert|i index newline                      Inserts the newline at the specified position
 
type cbot info for more info
type cbot quickstart for a quick interoduction
}
                    send_to_user(user, help_message)
                    return
                when "info"
info_message = %q{
Cbot is an interactive programming enviroment in irc. 
 
It supports 5 languages ruby, python, java, c++ and c.
 
It can work in different modes for each of these languages. 
    - In snippet mode, a number of useful files are allready imported and you are dropped right into the main function.
    - In program mode you have write a full program yourself.
    - Ruby and python also support interactive mode, which gives quick feedback on every command
 
Notes:
    Java is always compiles in the file Test.java, so your main class must also be called Test
    In ruby and python snippet and program mode are the same.
    In snippet mode the line numbers in the error messages will not always be accurate
 
type cbot help for a list of commands.
type cbot quickstart for a quick interoduction on how to get started.
}
                    send_to_user(user, info_message)
                    return
                when "quickstart"
info_message = %q{
You start by saying cbot new language mode, to get into your programming enviroment. From this point
cbot will assume everything you say until you pause or stop cbot is code. 
 
In interactive mode your code will yield immediate results but in the other modes, after you arere satisfied
with your code you need to say cbot r, to actually run it.
 
Other useful commands are
    cbot p                  lists your progress
    cbot delete line        deletes a line
    cbot edit line          edit a line
    cbot insert index line  insert a line at the given index
    cbot pause              pause entering code
    cbot continue              pause entering code
    cbot stop               stop entering code, all progress wil be lost
 
type cbot info for more indormation
type cbot help for a list of commands
}
                    send_to_user(user, info_message)
                    return
            end

            if !@active_user_enviroments.include? user
                send("#{user}, you are not in an active programming mode, use new (ruby|python|java|c|c++) (i|s|p)")
                return
            end

            #from here on we can be certain the user has an active enviroment to which we can direct commands
            case splitRequest[0]
                when "progress","print","p"
                    begin
                        if splitRequest.size > 2
                            if !(/^\d+$/ === splitRequest[1]) || !(/^\d+$/ === splitRequest[1])
                                raise RuntimeError.new("Not a number")
                            end
                            startIndex = splitRequest[1].to_i
                            stopIndex = splitRequest[2].to_i   
                        elsif splitRequest.size > 1
                            if !(/^\d+$/ === splitRequest[1])
                                raise RuntimeError.new("Not a number")
                            end
                            startIndex = splitRequest[1].to_i
                            stopIndex = splitRequest[1].to_i 
                        else
                            startIndex = 0
                            stopIndex = -1 
                        end
                        send(@active_user_enviroments[user].code_with_linenumbers(startIndex, stopIndex))
                    rescue RuntimeError => error
                        send("Invalid index(es)")
                    end
                when "delete","d"
                    begin
                        if splitRequest.size > 2
                            if !(/^\d+$/ === splitRequest[1]) || !(/^\d+$/ === splitRequest[1])
                                raise RuntimeError.new("Not a number")
                            end
                            startIndex = splitRequest[1].to_i
                            stopIndex = splitRequest[2].to_i   
                        elsif splitRequest.size > 1
                            if !(/^\d+$/ === splitRequest[1])
                                raise RuntimeError.new("Not a number")
                            end
                            startIndex = splitRequest[1].to_i
                            stopIndex = splitRequest[1].to_i 
                        else
                            startIndex = 0
                            stopIndex = -1 
                        end
                        send(@active_user_enviroments[user].remove_lines(startIndex, stopIndex))
                    rescue RuntimeError => error
                        puts error
                        send("Invalid index(es)")
                    end
                when "stop","s"
                    @active_user_enviroments.delete(user)

                when "add","a"
                    if splitRequest.size > 1
                        if @users.include? splitRequest[1]
                            @active_user_enviroments[splitRequest[1]] = @active_user_enviroments[user]
                        else
                            send("I do,'t know that user #{splitRequest[1]} you speak of")
                        end
                    else
                        send("You must specify a user that can help work on your code")
                    end
                when "edit", "e", "change"
                    begin
                        if splitRequest.size > 1
                            if !(/^\d+$/ === splitRequest[1])
                                raise RuntimeError.new("Not a number")
                            end
                            if splitRequest.size > 2
                                
                                @active_user_enviroments[user].change_line(splitRequest[1].to_i, splitRequest[2..-1].join(" "));
                            else
                                @active_user_enviroments[user].change_line(splitRequest[1].to_i, "");
                            end
                        else
                            send("You must supply an index")
                        end
                    rescue RuntimeError => error
                        puts error
                        send("Invalid index(es)")
                    end
                when "insert", "i"
                    begin
                        if splitRequest.size > 1
                            if !(/^\d+$/ === splitRequest[1])
                                raise RuntimeError.new("Not a number")
                            end
                            if splitRequest.size > 2
                                
                                @active_user_enviroments[user].insert_line(splitRequest[1].to_i, splitRequest[2..-1].join(" "));
                            else
                                @active_user_enviroments[user].insert_line(splitRequest[1].to_i, "");
                            end
                        else
                            send("You must supply an index")
                        end
                    rescue RuntimeError => error
                        puts error
                        send("Invalid index(es)")
                    end
                when "wait", "pause", "w"
                    @active_user_enviroments[user].pause = true
                when "continue", "c"
                    @active_user_enviroments[user].pause = false
                when "version", "v"
                    send(@active_user_enviroments[user].version)
                when "run", "r"
                    send(@active_user_enviroments[user].run_code(user))

            else
                send("unknown command: #{splitRequest[0]}")
            end
        else
            send("Yes ?")
        end
    end

    def receive_from(user, msg)
        splitMessage = msg.split(" ")
        if (splitMessage.size > 0)
            if (splitMessage[0] == @base_nick || splitMessage[0] == @nick)
                parse_request(user, splitMessage[1..-1])
                return
            end       
        end
        if @active_user_enviroments.include? user 
            if !@active_user_enviroments[user].pause
                output, errors = @active_user_enviroments[user].add_line(msg);
                send(output)
                send_to_user(user, errors)
            end
        end
        puts "#{user}: #{msg}"
    end

    def receive_private_from(user, msg)
        receive_from(user, msg)
    end
end


