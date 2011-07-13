require 'thread'
require 'time'
require 'timeout'
require 'open4'

#wrapper around a shell command
#usage: task = Task.new("shell command"); task.start
#You can check done to see if the task is finished
#done is threadsafe, all other methods and variables are not, check done before using them
#If the task is done or timed out, you can use result to see the result


class Task
    #maximum time in seconds an application gets to respond
    TIMEOUT = 5

    @done
    @errors
    @result
    @starttime
    @user

    attr_accessor :thread, :starttime, :status, :errors, :user

    #Returns true when the command is finished and the result is ready
    def done
        output = nil
        @lock.synchronize {
             output = @done
        }
        return output
    end

    #Returns the result, you should not use this function before you have verified done == true
    def result
        if @done
            return @result
        else
            Raise "You should not be checking result without verifying the task is done"
        end
    end

    def initialize(command, user)
        @lock = Mutex.new
        @command = command
        @done = false
        @starttime = Time.now()
        @user = user
    end

    def start
        pid, stdin, stdout, stderr = Open4.popen4("#{@command}")
        stdin.close()

        begin
            Timeout.timeout(TIMEOUT) {
                @result = stdout.readlines
                @errors = stderr.readlines
                stdout.close()
                stderr.close()

                if @result.empty?
                    @result = "no output"
                end
            }
        rescue Timeout::Error
            Process.kill("KILL", pid)
            @errors = "Timeout error: your command took more than #{TIMEOUT}s to complete, killed."
        end
        
        @lock.synchronize {
            @done = true
        }
    end

  private
    @lock
    @command

    def done=(isDone)
        @lock.synchronize {
            @done = isDone
        }
    end
end
