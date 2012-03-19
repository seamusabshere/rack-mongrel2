require 'rbczmq'
require 'rack/mongrel2/request'
require 'rack/mongrel2/response'

module Rack
  module Mongrel2
    class ConnectionDiedError < StandardError; end
    
    class Connection
      CTX = ZMQ::Context.new(1)

      def initialize(options)
        @uuid, @sub, @pub, @graceful_linger = options[:uuid], options[:recv], options[:send], options[:graceful_linger]

        # Connect to receive requests
        @reqs = CTX.connect(:PULL, @sub)
        @reqs.linger = 0

        # Connect to send responses
        @resp = CTX.connect(:PUB, @pub)
        @resp.identity = @uuid
        @resp.linger = 0
      end

      def recv
        msg = nil
        begin
          ready_sockets = ZMQ.select([@reqs], nil, nil, 30)
          if !ready_sockets.nil?
            ready_sockets[0].each do | socket |
              msg = socket.recv
              msg = Request.parse(msg) unless msg.nil?
            end
          end
        rescue RuntimeError => e
          raise ConnectionDiedError
        end
        msg
      end

      def reply(req, body, status = 200, headers = {})
        resp = Response.new(@resp)
        resp.send_http(req, body, status, headers)
        resp.close(req) if req.close?
      end

      def close
        if @graceful_linger
          @reqs.linger = @graceful_linger
          @resp.linger = @graceful_linger
        end
        @resp.close
        @reqs.close
        CTX.destroy
      end
    end
  end
end
