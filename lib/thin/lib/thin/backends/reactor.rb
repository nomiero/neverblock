require 'reactor'

# methods to implement

module Thin
  module Backends
    class Reactor < Base    

      # Allow using fibers in the backend.
      attr_writer :fibered    

      def fibered?; @fibered end
            
      def initialize(host, port, options={})
        @host    = host
        @port    = port.to_i
        @timeout = 30       
        @reactor = ::Reactor::Base.new        
      end
          
      def start
        # start the server
        @server_socket = ::TCPServer.new(@host, @port)
        @server_socket.listen(1024)
        @reactor.attach(:read, @server_socket) do |server, reactor|
          # we create new connections here
          # then decide if we close or persist them
          # we also need to handle timeouts for persistent connections
          begin
            loop do
#             conn = @server_socket.accept_nonblock
#              conn.gets("\r\n\r\n")
#            conn.write("HTTP/1.1 200 OK\r\n\r\nHi")
#           conn.close
              Kernel.puts "in loop"
              connection = accept_connection(server)
            end
          rescue Errno::EWOULDBLOCK, Errno::EAGAIN, Errno::EINTR
          rescue Exception => e
          
          end
        end        
        loop do
          Fiber.new do
            @reactor.run
          end.resume
          break unless @reactor.running?
        end
        @server_socket.close
      end
      
      def stop
        @reactor.stop
      end
      
      alias :stop! :stop    
            
      def close
      end
      
      def empty?
        size.zero?
      end
    
      def size
        0 # TODO
      end

      def trace=(trace)
        @trace = trace
      end
      
      def maxfds=(maxfds)
        raise "not implemented"
      end
      
      def maxfds 
        raise "not implemented"
      end
      
      def to_s
        "#{@host}:#{@port} (Reactor)"
      end
      
      def running?
        @reactor.running?
      end
      
      protected
        
        def accept_connection(server)
          connection = ReactorConnection.new(server.accept_nonblocking)
          initialize_connection(connection)
        end

        # Initialize a new connection to a client.
        def initialize_connection(connection)
          connection.backend                 = self
          connection.app                     = @server.app
          connection.comm_inactivity_timeout = @timeout
          connection.threaded                = false
 
          # We control the number of persistent connections by keeping
          # a count of the total one allowed yet.
          if @persistent_connection_count < @maximum_persistent_connections
            connection.can_persist!
            @persistent_connection_count += 1
          end
 
          @connections << connection
        end
            
    end
  end
end
  
