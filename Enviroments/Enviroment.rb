#interface description of a programming enviroment

class Enviroment

  #An implementation of Enviroment MUST override the following functions
  public
    #run the program/snippet, compiler languages should also compile first, can returns a string reporting errors/results or start a Task to report
    def run_code(user)
        Raise "Method run must be overridden"
    end
    #return language as a string
    def language
        Raise "Method language must be overridden"
    end

  #an implementation of Enviroment CAN override the following functions
  public
    #compile the program, may return a string
    def compile; end
    #returns version info
    def version; end
    #return code with framework included as string
    def program
        return code
    end
    #return code with framework included and line numbers as string
    def program_with_linenumbers
        return code_with_linenumbers
    end
    #perform auto indentation and other markup changes
    def prettify; end

  private
    #mode changed, mode can be CodeBot::Mode::INTERACTIVE, CodeBot::Mode::SNIPPET, CodeBot::Mode::PROGRAM
    def mode_changed(mode); end
    #a new line has been added to the console/snippet/program, may return a string
    def line_added(line); end
    #a line is about to be removed from the program, may return a string
    def line_removed(index); end
    #a line in the program has been changed, may return a string
    def line_changed(index); end


  #common Enviroment implementation
  @lines
  @mode
  @pause

  attr_reader :lines, :mode
  attr_accessor :pause

  public
    attr_reader :lines, :mode
    attr_accessor :pause

    def add_line(line)
        @lines.push(line)
        return line_added(line)
    end

    def change_line(index, line)
        if index >= @lines.size
            return "index out of range"
        end
        @lines[index] = line
        return line_changed(line)
    end

    def insert_line(index, line)
        if index >= @lines.size
            return "index out of range"
        end
        @lines.insert(index, line)
        return line_changed(line)
    end

    #removes lines in between and including start and stop
    def remove_lines(start, stop) 
        start, stop = parse_range(start, stop)
        if start > stop
            return "start index must be larger than or equal to stop index"
        end
        (start..stop).each{|index|
            line_removed(index)
        }
        @lines.slice!(start..stop)
    end

    #set mode
    def mode=(mode)
        @mode = mode
        return mode_changed(mode)
    end

    #removes given line
    def remove_line(index)
        return remove_lines(index, index)
    end

    def undo_line
        return remove_lines(-1, -1)
    end

    #returns codewith line numbers as array of lines
    #Arguments are none: print from first to last line, 1: prints from arg[0] to last lines, 2: print from arg[0] to arg[1]
    #negative indexes, starting from the end are supported
    def code_with_linenumbers(start, stop)
        start, stop = parse_range(start, stop)
        if start > stop
            return "start index must be larger than or equal to stop index"
        end

        newlines = []
        max_space = (@lines.size == 0) ? 0 : (Math.log10(@lines.size)).floor

        pp start, stop
        for i in start..stop
            newlines.push(" " * (max_space - ((i == 0) ? 0 : (Math.log10(i)).floor)) + i.to_s+ ": " + @lines[i])
        end
        return newlines
    end

  protected
    def initialize(task_list, command_prefix)
        @lines = []
        @pause = false
        @task_list = task_list
        @dir = Dir.tmpdir+"/"+rand.to_s+"/"
        @command_prefix = command_prefix
        Dir.mkdir(@dir)
    end

    def parse_range(start, stop)
        if start < 0
            start = (@lines.size()+start)
        end
        if stop < 0
            stop = (@lines.size()+stop)
        end
        start = [start, -@lines.size()].max
        stop = [stop, -@lines.size()].max

        return start, stop
    end


end
