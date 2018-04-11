require 'webrick'
require 'spec_helper'
require 'json'

describe 'Bugsnag' do
  server = nil
  queue = Queue.new

  describe 'with a proxy' do
    proxy = nil
    pqueue = Queue.new

    before do
      proxy = WEBrick::HTTPServer.new :Port => 0, :Logger => WEBrick::Log.new("/dev/null"), :AccessLog => []
      proxy.mount_proc '/' do |req, res|
        pqueue.push req
        res.status = 200
        res.body = "OK\n"
      end
      Thread.new{ proxy.start }
    end
    after do
      proxy.stop
    end

    let(:proxied_request) { pqueue.pop }

    it 'should use a proxy when configured' do
      Bugsnag.configure do |config|

        config.endpoint = "http://localhost:#{server.config[:Port]}"

        config.proxy_host = 'localhost'
        config.proxy_port = proxy.config[:Port]
        config.proxy_user = 'conrad'
        config.proxy_password = '$ecret'
      end

      Bugsnag.notify 'oy'

      r = proxied_request

      expect(r.header['proxy-authorization'].first).to eq("Basic Y29ucmFkOiRlY3JldA==")
      expect(r.request_line).to eq("POST http://localhost:#{server.config[:Port]}/ HTTP/1.1\r\n")
    end
  end
end
