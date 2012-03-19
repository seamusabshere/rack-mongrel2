require 'stringio'
require 'multi_json'
require 'rack/mongrel2/connection'

module Rack
  module Mongrel2
    def self.run(app, options = {})
      
      raise ArgumentError.new('Must specify :recv') if options[:recv].nil?
      raise ArgumentError.new('Must specify :recv') if options[:send].nil?
      raise ArgumentError.new('Must specify :uuid') if options[:uuid].nil?

      conn = Connection.new(options)

      running = true
      graceful_shutdown = false

      %w(INT TERM KILL).each do | sig |
        Signal.trap(sig) do
          running = false
          graceful_shutdown = (sig == 'TERM')
        end
      end
      
      begin 
        while running do
          req = conn.recv
          next if req.nil? || req.disconnect?
          break if !running

          env = { 'rack.version'        => Rack::VERSION,
                  'rack.url_scheme'     => 'http', # Only HTTP for now
                  'rack.input'          => StringIO.new(req.body),
                  'rack.errors'         => $stderr,
                  'rack.multithread'    => true,
                  'rack.multiprocess'   => true,
                  'rack.run_once'       => false,
                  'mongrel2.pattern'    => req.headers['PATTERN'],
                  'REQUEST_METHOD'      => req.headers['METHOD'],
                  'SCRIPT_NAME'         => '', # like unicorn
                  'PATH_INFO'           => req.path,
                  'QUERY_STRING'        => req.headers['QUERY'] || '' }

          env['SERVER_NAME'], env['SERVER_PORT'] = req.headers['host'].split(':', 2)
          req.headers.each do |key, val|
            unless key =~ /content_(type|length)/i
              key = "HTTP_#{key.upcase.gsub('-', '_')}"
            end
            env[key] = val
          end

          status, headers, rack_response = app.call(env)
          body = ''
          rack_response.each { |b| body << b }
          conn.reply(req, body, status, headers)
        end
      rescue ConnectionDiedError => e
        conn.close
        exit
        return
      ensure
        conn.close if graceful_shutdown
      end
    end
  end
end
