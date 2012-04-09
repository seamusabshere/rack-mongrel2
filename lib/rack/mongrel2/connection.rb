require 'zmq2'
require 'rack/mongrel2/request'
require 'rack/mongrel2/response'

module Rack
  module Mongrel2
    class ConnectionDiedError < StandardError; end
    
    class Connection
      CONTEXT = ::ZMQ::Context.new(1)

      def initialize(options)
        @uuid, @sub, @pub, @graceful_linger = options[:uuid], options[:recv], options[:send], options[:graceful_linger]

        # Connect to receive requests
        @incoming = CONTEXT.socket(::ZMQ::PULL)
        @incoming.connect(@sub)
        @incoming.setsocketopt(::ZMQ::LINGER, 0)

        # Connect to send responses
        @outgoing = CONTEXT.socket(::ZMQ::PUB)
        @outgoing.connect(@pub)
        @outgoing.setsocketopt(::ZMQ::IDENTITY, @uuid)
        @outgoing.setsocketopt(::ZMQ::LINGER, 0)
      end

      def recv
        msg = nil
        begin
          ready_sockets = ::ZMQ.select([@incoming], nil, nil, 30)
          if !ready_sockets.nil?
            ready_sockets[0].each do | socket |
              msg = socket.recv
              msg = Request.parse(msg) unless msg.nil?
            end
          end
        rescue RuntimeError => e
          $stderr.puts "[rack-mongrel2] Rescued from #{e.inspect}"
          raise ConnectionDiedError
        end
        msg
      end

      def reply(req, body, status = 200, headers = {})
        resp = Response.new(@outgoing)
        resp.send_http(req, body, status, headers)
        resp.close(req) if req.close?
      end

      def close
        if @graceful_linger
          @incoming.setsocketopt(::ZMQ::LINGER, @graceful_linger)
          @outgoing.setsocketopt(::ZMQ::LINGER, @graceful_linger)
        end
        @outgoing.close
        @incoming.close
        CONTEXT.destroy
      end
    end
  end
end
