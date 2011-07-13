require 'socket'
require 'pp'
require 'fcntl'
require 'thread'

#This class implements the basic functionality of an irc client. The class performs the following functions:
#   - connect server to a channel new (server, port, channel, nick, description)
#   - receive parsed messages (override receive/receive_from/receive_private/receive_private_from)
#   - send messages to channel (send/send_to_use)
#   - maintains a userlist you can use to look uk more data on a user (users)

class IrcClient

  MAX_IRC_MESSAGE_LENGTH = 512 #as defined in RFC2812
  BUFFER_SIZE = 2 * MAX_IRC_MESSAGE_LENGTH #min buffer size that guaranteed 1 complete message
  MAX_LINES = 10
  MAX_PRIVATE_LINES = 50

  class User
    attr_accessor :nick,:fullname,:hostname,:servername
  end

  public
    #{nick -> User} map
    attr_reader :users #{nick -> User}

    #functions to override
    def receive(message) end
    def receive_from(user, message) end
    def receive_private(message) end
    def receive_private_from(user, message) end
    def user_join(user) end
    def user_left(user) end
    def tick() end

    #function to send a message or array of messages to the channel
    def send(message)
        return if !message
        return if message == ""
        if message.include?("\n")
            message = message.split("\n") 
        end
        if message.instance_of? Array
            if message.size > MAX_LINES
                message = message[0...MAX_LINES]
            end
            message.each{|msg|
                send(msg)
            }
        else
            puts ":#{@nick} PRIVMSG #{@channel} :#{message}"
            rawSend ":#{@nick} PRIVMSG #{@channel} :#{message}"
        end
    end

    #function to send a private message or array of messages to a specific user
    def send_to_user(user, message)
        return if !message
        return if message == ""
        if message.include?("\n")
            message = message.split("\n") 
        end
        if message.instance_of? Array
            if message.size > MAX_PRIVATE_LINES
                message = message[0...MAX_PRIVATE_LINES]
            end
            message.each{|msg|
                send_to_user(user,msg)
            }
        else
            puts ":#{@nick} PRIVMSG #{user} :#{message}"
            rawSend ":#{@nick} PRIVMSG #{user} :#{message}"
        end
    end

    #change the nickname
    def change_nick(nick)
        rawSend ":#{@nick} NICK #{nick}"
        @nick = nick
    end

    def initialize(server, port, channel, nick, description)
        @base_nick = nick
        @server = server
        @nick = nick
        @port = port
        @description = description
        @channel = channel
    end

    def connect
        #@socket = TCPSocket.open(@server, @port)
        #addr = Socket.getaddrinfo(@server, nil)
        #sockaddr = Socket.pack_sockaddr_in(@port, addr[0][3])
        #@socket = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)

        @socket = TCPSocket.new(@server, @port)

        login
        join_channel
    end


    def login
        rawSend "NICK #{@nick}"
        rawSend "USER #{@nick} * * :#{@description}"
    end

    def join_channel(*args)
        @users = {}
        rawSend "JOIN #{@channel}"
        rawSend "WHO #{@channel}"       
    end

    def part_channel(*args)
        @users = {}
        rawSend "PART #{@channel}"    
    end

    def close
        @socket.close
    end

    def stop
        @stop = true
    end

    def loop
        buffer = ""
        while not @stop
            begin
                #fill a buffer non-blockish until we can split of a message
                buffer += @socket.recv_nonblock(BUFFER_SIZE)
                split = buffer.index("\n")
                while split != nil
                    message = buffer[0..split]
                    buffer = buffer[split+1..-1]
                    parse_message(message)
                    split = buffer.index("\n")
                end
                tick
            rescue StandardError => error
                tick
                `sleep 0.01` #ruby sleep call is totally inreliable after opening a thread
            end
        end
    end

  private

    @fiber_pool

    def rawSend(message)
        @socket.send "#{message}\n", 0
    end

    def parse_user_who(splitMessage)
        user = User.new
        user.nick = splitMessage[7]
        user.hostname = splitMessage[4]
        user.servername = splitMessage[5]
        user.fullname = splitMessage[10..-1].join(" ")
        @users[user.nick] = user
    end

    def parse_user_whois(splitMessage)
        user = User.new
        user.nick = splitMessage[3]
        user.hostname = splitMessage[4]
        user.servername = splitMessage[5]
        user.fullname = splitMessage[7..-1].join(" ")[1..-1]
        @users[user.nick] = user
    end

    def parse_message(message)
        if !message
            connect #tries a reconnect once
            return 
        end

        message.strip!

        splitMessage = message.split(" ")
        origin = splitMessage[0][1..-1]
        name = origin.split("@")[0]
        server = origin.split("@")[1]
        nick = origin.split("!")[0]
        command = splitMessage[1]
        channel = splitMessage[2]
        content = /^:?.*?:(.*)/.match(message)[1]

        puts content

        if message.strip =~ /^PING :(.+)$/i
            rawSend "PONG :#{$1}"
            return
        end

        case(command)  
          when "PRIVMSG"
            if channel == @channel
              receive(content)
              receive_from(nick, content)
            elsif channel == @nick
              receive_private(content)
              receive_private_from(nick, content)
            end
          when "PART", "QUIT"
            @users.delete(nick)
            user_left(nick)
          when "JOIN"
            user = User.new
            user.nick = nick
            @users[nick] = user
            #rawSend("WHOIS #{nick}") #detailed user info is nice but not worth the time
            user_join(nick)
          when "352" #who reply
            parse_user_who(splitMessage)
          when "311" #whois reply
            parse_user_whois(splitMessage)
          when "433" #nickname in use
            @nick += "_"
            login
            join_channel
          when "376" #end MOTD
            #many irc server freak when you send them a join immediatly 
            #after logging in allthough the standard allows it, but now
            #things have settled, they should be more receptive
            join_channel
          when "KICK"
            join_channel #i will not be silenced
          when "474"
            raise "Cannot join channel reason: #{content}" #i was probably banned for refusing to be kicked
        else
            puts message
        end
    end
end
