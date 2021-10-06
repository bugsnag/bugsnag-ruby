# encoding: utf-8
require 'webrick'
require 'spec_helper'
require 'json'

describe Bugsnag::SessionTracker do
  server = nil
  queue = Queue.new

  before do
    server = WEBrick::HTTPServer.new :Port => 0, :Logger => WEBrick::Log.new("/dev/null"), :AccessLog => []
    server.mount_proc '/' do |req, res|
      headers = []
      req.each { |header| headers << header }
      queue << [JSON.parse(req.body), headers]
      res.status = 202
      res.body = "OK\n"
    end
    Thread.new { server.start }
  end

  before(:each) do
    Bugsnag.instance_variable_set(:@session_tracker, Bugsnag::SessionTracker.new)
  end

  after do
    Bugsnag.configure do |conf|
      conf.auto_capture_sessions = false
      conf.delivery_method = :synchronous
    end
    server.stop
    queue.clear
  end

  after(:all) do
    Bugsnag.instance_variable_set(:@session_tracker, Bugsnag::SessionTracker.new)
  end

  it 'adds session object to queue' do
    tracker = Bugsnag::SessionTracker.new
    tracker.start_session
    expect(tracker.session_counts.size).to eq(1)
    time = tracker.session_counts.keys.last
    count = tracker.session_counts[time]

    expect(count).to eq(1)
  end

  it 'stores session in thread' do
    tracker = Bugsnag::SessionTracker.new
    tracker.start_session
    session = Thread.current[Bugsnag::SessionTracker::THREAD_SESSION]
    expect(session.include? :id).to be true
    expect(session.include? :startedAt).to be true
    expect(session.include? :events).to be true
    expect(session[:events].include? :handled).to be true
    expect(session[:events].include? :unhandled).to be true
    expect(session[:events][:handled]).to eq(0)
    expect(session[:events][:unhandled]).to eq(0)
  end

  it 'gives unique ids to each session' do
    tracker = Bugsnag::SessionTracker.new
    tracker.start_session
    session_one = Thread.current[Bugsnag::SessionTracker::THREAD_SESSION]
    tracker.start_session
    session_two = Thread.current[Bugsnag::SessionTracker::THREAD_SESSION]
    expect(session_one[:id]).to_not eq(session_two[:id])
  end

  it 'will not create sessions if Configuration.enable_sessions is false' do
    Bugsnag.configure do |conf|
      conf.set_endpoints("http://localhost:#{server.config[:Port]}", nil)
    end
    expect(Bugsnag.configuration.enable_sessions).to eq(false)
    expect(Bugsnag.session_tracker.session_counts.size).to eq(0)
    Bugsnag.start_session
    expect(Bugsnag.session_tracker.session_counts.size).to eq(0)
  end

  it 'will not create sessions if the release stage is not enabled' do
    Bugsnag.configure do |config|
      config.enabled_release_stages = ['abc']
      config.release_stage = 'xyz'
    end

    expect(Bugsnag.configuration.enable_sessions).to eq(true)
    expect(Bugsnag.session_tracker.session_counts.size).to eq(0)

    Bugsnag.start_session

    expect(Bugsnag.session_tracker.session_counts.size).to eq(0)

    Bugsnag.configuration.release_stage = 'abc'

    Bugsnag.start_session

    expect(Bugsnag.session_tracker.session_counts.size).to eq(1)
  end

  it 'sends sessions when send_sessions is called' do
    Bugsnag.configure do |conf|
      conf.auto_capture_sessions = true
      conf.delivery_method = :synchronous
      conf.set_endpoints("http://localhost:#{server.config[:Port]}", "http://localhost:#{server.config[:Port]}")
    end
    WebMock.allow_net_connect!
    Bugsnag.start_session
    expect(Bugsnag.session_tracker.session_counts.size).to eq(1)
    Bugsnag.session_tracker.send_sessions
    expect(Bugsnag.session_tracker.session_counts.size).to eq(0)
    payload, headers = queue.pop
    expect(payload.include?("app")).to be true
    expect(payload.include?("notifier")).to be true
    expect(payload.include?("device")).to be true
    expect(payload.include?("sessionCounts")).to be true
    expect(payload["sessionCounts"].size).to eq(1)
  end

  it 'sets details from config' do
    Bugsnag.configure do |conf|
      conf.auto_capture_sessions = true
      conf.release_stage = "test_stage"
      conf.delivery_method = :synchronous
      conf.set_endpoints("http://localhost:#{server.config[:Port]}", "http://localhost:#{server.config[:Port]}")
    end
    WebMock.allow_net_connect!
    Bugsnag.start_session
    expect(Bugsnag.session_tracker.session_counts.size).to eq(1)
    Bugsnag.session_tracker.send_sessions
    expect(Bugsnag.session_tracker.session_counts.size).to eq(0)
    payload, headers = queue.pop
    notifier = payload["notifier"]
    expect(notifier.include?("name")).to be true
    expect(notifier["name"]).to eq(Bugsnag::Report::NOTIFIER_NAME)
    expect(notifier.include?("url")).to be true
    expect(notifier["url"]).to eq(Bugsnag::Report::NOTIFIER_URL)
    expect(notifier.include?("version")).to be true
    expect(notifier["version"]).to eq(Bugsnag::Report::NOTIFIER_VERSION)

    app = payload["app"]
    expect(app.include?("releaseStage")).to be true
    expect(app["releaseStage"]).to eq(Bugsnag.configuration.release_stage)
    expect(app.include?("version")).to be true
    expect(app["version"]).to eq(Bugsnag.configuration.app_version)
    expect(app.include?("type")).to be true
    expect(app["type"]).to eq(Bugsnag.configuration.app_type)

    device = payload["device"]
    expect(device.include?("hostname")).to be true
    expect(device["hostname"]).to eq(Bugsnag.configuration.hostname)
    expect(device["runtimeVersions"]["ruby"]).to eq(Bugsnag.configuration.runtime_versions["ruby"])
  end

  context "#pause_session" do
    it "does nothing if there is no current session" do
      Bugsnag.pause_session

      expect(Bugsnag::SessionTracker.get_current_session).to be(nil)
    end

    it "marks the current session as paused if one exists" do
      Bugsnag.start_session

      expect(Bugsnag::SessionTracker.get_current_session[:paused?]).to be(false)

      Bugsnag.pause_session

      expect(Bugsnag::SessionTracker.get_current_session[:paused?]).to be(true)
    end

    it "does nothing if the current session is already paused" do
      Bugsnag.start_session

      expect(Bugsnag::SessionTracker.get_current_session[:paused?]).to be(false)

      Bugsnag.pause_session

      expect(Bugsnag::SessionTracker.get_current_session[:paused?]).to be(true)

      Bugsnag.pause_session

      expect(Bugsnag::SessionTracker.get_current_session[:paused?]).to be(true)
    end
  end

  context "#resume_session" do
    it "returns false and does nothing when there is a current session" do
      Bugsnag.start_session

      expect(Bugsnag::SessionTracker.get_current_session[:paused?]).to be(false)

      expect(Bugsnag.resume_session).to be(false)

      expect(Bugsnag::SessionTracker.get_current_session[:paused?]).to be(false)
    end

    it "returns false and does nothing when a session is started after one has been paused" do
      Bugsnag.start_session
      Bugsnag.pause_session
      Bugsnag.start_session

      expect(Bugsnag::SessionTracker.get_current_session[:paused?]).to be(false)

      expect(Bugsnag.resume_session).to be(false)

      expect(Bugsnag::SessionTracker.get_current_session[:paused?]).to be(false)
    end

    it "returns false and starts a new session when there is no current or paused session" do
      expect(Bugsnag.resume_session).to be(false)

      expect(Bugsnag::SessionTracker.get_current_session).not_to be(nil)
    end

    it "returns true and makes the paused session the active session when there is no current session" do
      Bugsnag.start_session
      Bugsnag.pause_session

      expect(Bugsnag::SessionTracker.get_current_session[:paused?]).to be(true)

      expect(Bugsnag.resume_session).to be(true)

      expect(Bugsnag::SessionTracker.get_current_session).not_to be(nil)
    end
  end
end
