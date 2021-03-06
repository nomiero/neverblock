require File.expand_path(File.dirname(__FILE__)+'/../neverblock')

# methods to implement
=begin
#GC.disable
Thread.new do
  loop do
    sleep 0.5
    GC.enable
    GC.start
    GC.disable
  end
end
=end

module Thin
  module Backends
    class NeverBlock < Base    

      # Allow using fibers in the backend.
      def fibered?; true; end
            
      def initialize(host, port, options={})
        @host    = host
        @port    = port.to_i
        @timeout = 30
        Kernel.puts "inside neverblock backend"       
      end
          
      def start
        @reactor = NB.reactor
        @server_socket = TCPServer.new(@host, @port)
        @server_socket.listen(511)
        Kernel.puts "before anything"
        @reactor.attach(:read, @server_socket) do |server, reactor|
          begin
            loop do
              Kernel.puts "before accept_connection"
              connection = accept_connection
            end
          rescue Errno::EWOULDBLOCK, Errno::EAGAIN, Errno::EINTR
          rescue Exception => e
            STDERR.puts e +"first exception"
          end
        end        
        loop do
          begin
            NB::Fiber.new do
               Kernel.puts "inside reactor fiber loop"
              @reactor.run
            end.resume
           Kernel.puts "outside reactor fiber loop"
            break unless @reactor.running?
          rescue Exception => e
            puts e +"second exception"
            puts e.backtrace
            p @reactor
          end
        end
        @server_socket.close
      end
      
      def stop;@reactor.stop;end
      
      alias :stop! :stop    
            
      def trace=(trace);@trace = trace;end
      
      def maxfds=(maxfds);raise "not implemented";end
      
      def maxfds;raise "not implemented";end
      
      def to_s;"#{@host}:#{@port} (NeverBlock)";end
      
      def running?;@reactor.running?;end
      
      protected
        
        def accept_connection
          Kernel.puts "before accept nonblock"
          socket = @server_socket.accept_nonblock
          Kernel.puts "after accept nonblock"
          connection = ::Thin::ReactorConnection.new(socket, @reactor)
          connection.backend                 = self
          connection.app                     = @server.app
          connection.threaded                = false
          connection.post_init
        end
            
    end
  end
end
  
