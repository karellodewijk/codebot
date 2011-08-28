require './CodeBot'


command_prefix = ""
if ARGV.size != 0 then
    command_prefix = ARGV.join(" ")
end

puts command_prefix
client = CodeBot.new("localhost", "#testcodebot", 6667, command_prefix)
#client = CodeBot.new("efnet.xs4all.nl", "#dreamincode", 6667, command_prefix)

while true
    begin
        client.connect
        client.loop
    rescue StandardError => error
        puts error.class
        puts error
        puts error.backtrace();   
        redo
    end
end

