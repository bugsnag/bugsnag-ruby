require 'webrick'
require 'spec_helper'

describe 'Bugsnag' do
  server = nil
  queue = Queue.new

  before do
    server = WEBrick::HTTPServer.new :Port => 0, :Logger => WEBrick::Log.new("/dev/null"), :AccessLog => []
    server.mount_proc '/' do |req, res|
      queue.push req.body
      res.status = 200
      res.body = "OK\n"
    end
    Thread.new{ server.start }
  end
  after do
    server.stop
  end

  let(:request) { JSON.parse(queue.pop) }

  it 'should send notifications over the wire' do
    Bugsnag.configure do |config|
      config.endpoint = "localhost:#{server.config[:Port]}"
      config.use_ssl = false
    end

    Bugsnag.notify 'yo'

    expect(request['events'][0]['exceptions'][0]['message']).to eq('yo')
  end
end
