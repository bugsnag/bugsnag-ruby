require 'webrick'
require 'spec_helper'
require 'json'

describe "Bugsnag Rake integration" do
  describe Bugsnag::Middleware::Rake do
    it "adds rake data to the report" do
      callback = double

      task = double
      allow(task).to receive_messages(
        :name => "TEST_NAME",
        :full_comment => "TEST_COMMENT",
        :arg_description =>"TEST_ARGS"
      )

      report = double("Bugsnag::Report") 
      expect(report).to receive(:request_data).and_return({
        :bugsnag_running_task => task
      })
      expect(report).to receive(:add_tab).with(:rake_task, {
        :name => "TEST_NAME",
        :description => "TEST_COMMENT",
        :arguments => "TEST_ARGS"
      })
      expect(report).to receive(:automatic_context).with(no_args)
      expect(report).to receive(:automatic_context=).with("TEST_NAME")

      expect(callback).to receive(:call).with(report)

      middleware = Bugsnag::Middleware::Rake.new(callback)
      middleware.call(report)
    end
  end

  describe "Bugsnag::Rake" do
    server = nil
    queue = Queue.new

    before do
      server = WEBrick::HTTPServer.new :Port => 0, :Logger => WEBrick::Log.new("/dev/null"), :AccessLog => []
      server.mount_proc '/' do |req, res|
        queue.push req.body
        res.status = 200
        res.body = "OK\n"
      end
      Thread.new { server.start }
    end

    after do
      server.stop
      queue.clear
    end

    it 'should run the rake middleware when rake tasks crash' do
      ENV['BUGSNAG_TEST_SERVER_PORT'] = server.config[:Port].to_s
      task_fixtures_path = File.join(File.dirname(__FILE__), '../fixtures', 'tasks')
      Dir.chdir(task_fixtures_path) do
        system("../../../bin/rake test:crash")
      end

      result = nil
      attempts = 0

      while result.nil? && attempts < 20
        begin
          sleep 0.1
          attempts += 1

          result = queue.pop(true)
        rescue ThreadError
        end
      end

      expect(result).not_to be_nil

      result = JSON.parse(result)

      expect(result["events"][0]["metaData"]["rake_task"]).not_to be_nil
      expect(result["events"][0]["metaData"]["rake_task"]["name"]).to eq("test:crash")
      expect(result["events"][0]["app"]["type"]).to eq("rake")
      expect(result["events"][0]["device"]["runtimeVersions"]["rake"]).to match(/\A\d+\.\d+\.\d+/)
    end
  end
end
