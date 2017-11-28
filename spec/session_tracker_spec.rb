# encoding: utf-8
require 'spec_helper'

describe Bugsnag::SessionTracker do
  before do
    @config = Bugsnag::Configuration.new
    @config.track_sessions = true
  end

  after do
    Bugsnag.configure do |conf|
      conf.track_sessions = false
    end
  end

  it 'does not create session object if disabled' do
    config = Bugsnag::Configuration.new
    config.track_sessions = false
    tracker = Bugsnag::SessionTracker.new(config)
    tracker.create_session
    expect(tracker.delivery_queue.size).to eq(0)
  end

  it 'adds session object to queue' do
    tracker = Bugsnag::SessionTracker.new(@config)
    tracker.create_session
    expect(tracker.delivery_queue.size).to eq(1)
    session = tracker.delivery_queue.pop
    expect(session.include? :id).to be true
    expect(session.include? :user).to be true
    expect(session.include? :startedAt).to be true
    expect(session[:user]).to be nil
  end

  it 'stores a user object in the session' do
    tracker = Bugsnag::SessionTracker.new(@config)
    tracker.create_session({:name => "Jimmy"})
    expect(tracker.delivery_queue.size).to eq(1)
    session = tracker.delivery_queue.pop
    expect(session.include? :user).to be true
    expect(session[:user]).to eq({:name => "Jimmy"})
  end

  it 'stores session in thread' do
    tracker = Bugsnag::SessionTracker.new(@config)
    tracker.create_session
    session = Thread.current[Bugsnag::SessionTracker::THREAD_SESSION]
    expect(session.include? :id).to be true
    expect(session.include? :user).to be false
    expect(session.include? :startedAt).to be true
    expect(session.include? :events).to be true
    expect(session[:events].include? :handled).to be true
    expect(session[:events].include? :unhandled).to be true
    expect(session[:events][:handled]).to eq(0)
    expect(session[:events][:unhandled]).to eq(0)
  end

  it 'gives unique ids to each session' do
    tracker = Bugsnag::SessionTracker.new(@config)
    tracker.create_session
    tracker.create_session
    expect(tracker.delivery_queue.size).to eq(2)
    session_one = tracker.delivery_queue.pop
    session_two = tracker.delivery_queue.pop
    expect(session_one[:id]).to_not eq(session_two[:id])
  end

  it 'sends sessions when send_sessions is called' do
    Bugsnag.configure do |conf|
      conf.track_sessions = true
    end
    Bugsnag.session_tracker.create_session
    expect(Bugsnag.session_tracker.delivery_queue.size).to eq(1)
    Bugsnag.session_tracker.send_sessions
    expect(Bugsnag.session_tracker.delivery_queue.size).to eq(0)
    expect(Bugsnag).to have_sent_sessions{ |payload, headers|
      expect(payload.include?("app")).to be true
      expect(payload.include?("notifier")).to be true
      expect(payload.include?("device")).to be true
      expect(payload.include?("sessions")).to be true
      expect(payload["sessions"].size).to eq(1)
    }
  end

  it 'sets details from config' do
    Bugsnag.configure do |conf|
      conf.track_sessions = true
      conf.release_stage = "test_stage"
    end
    Bugsnag.session_tracker.create_session
    expect(Bugsnag.session_tracker.delivery_queue.size).to eq(1)
    Bugsnag.session_tracker.send_sessions
    expect(Bugsnag.session_tracker.delivery_queue.size).to eq(0)
    expect(Bugsnag).to have_sent_sessions{ |payload, headers|
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
    }
  end

  it 'uses middleware to attach session to notification' do
    Bugsnag.configure do |conf|
      conf.track_sessions = true
      conf.release_stage = "test_stage"
    end
    Bugsnag.session_tracker.create_session
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = payload["events"][0]
      expect(event.include?("session")).to be true
      session = event["session"]
      expect(session.include?("id")).to be true
      expect(session.include?("startedAt")).to be true
      expect(session.include?("events")).to be true
      sesevents = session['events']
      expect(sesevents.include?("unhandled")).to be true
      expect(sesevents["unhandled"]).to eq(0)
      expect(sesevents.include?("handled")).to be true
      expect(sesevents["handled"]).to eq(1)
    }
  end

end
