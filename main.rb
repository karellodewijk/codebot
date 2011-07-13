require './CodeBot'

client = CodeBot.new("localhost", "#testcodebot", 6667)
#client = CodeBot.new("localhost", "#testcodebot", 6667)
#client = CodeBot.new("efnet.xs4all.nl", "#dreamincode", 6667)

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

