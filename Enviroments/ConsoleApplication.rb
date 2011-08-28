require 'open4'


class ConsoleApplication
    MAX_CHARS = 100
    TIMEOUT = 1

    def initialize(name, prompt, command_prefix)
        @name = name
        @prompt = prompt
        @command_prefix = command_prefix
    end

    def start
        puts "running"
        puts @name
        @pid, @stdin, @stdout, @stderr = Open4.popen4(@name)
        result = read_until_prompt(TIMEOUT)
        return result
    end

    def write(line)
        @stdin.puts line
        @stdin.flush
        result = read_until_prompt(TIMEOUT)
        return result
    end

    def read
        begin
            result += @stdout.read_nonblock(MAX_CHARS)
        rescue
        end
        return result
    end

    def read_until_prompt_timeout
        Timeout.timeout(0.5) {
            read_until_prompt
        }      
    end

    def read_until_prompt(timeout)
        starttime = Time.now
        result = ""
        while true
            begin
                while !result.include?(@prompt)
                    if (Time.now - starttime > timeout)
                        #todo: Killing the entire console is perhaps a little bruteforce
                        begin
                            Process.kill(9, @pid) #kill console
                        rescue Exception => error
                            begin
                                system("#{@command_prefix} kill #{@pid}") #kill console in case the command prefix is a nessecity
                            rescue Exception => error
                                puts error
                            end
                        end
                        @pid, @stdin, @stdout, @stderr = Open4.popen4("#{@command_prefix} #{@name}") #new console
                        read_until_prompt(TIMEOUT)
                        @errormessage = "Timeout error: your command took more than #{TIMEOUT}s to complete, killed"
                        return 
                    end
                    @stdout.flush
                    result += @stdout.read_nonblock(MAX_CHARS)
                end
                break
            rescue Errno::EAGAIN => error
                #puts error
                redo
            end
        end
        return result       
    end

    def errors
        begin
            result = @stderr.read_nonblock(MAX_CHARS)
        rescue
        end
        if @errormessage
            result = ((result == nil) ? "" : result) + @errormessage
            @errormessage = nil
        end
        puts result
        return result
    end
end
