require 'thread'
require 'time'
require 'securerandom'

module Bugsnag
  class SessionTracker

    THREAD_SESSION = "bugsnag_session"
    MAXIMUM_SESSION_COUNT = 100
    SESSION_PAYLOAD_VERSION = "1.0"

    attr_reader :session_counts
    attr_accessor :track_sessions

    def self.set_current_session(session)
      Thread.current[THREAD_SESSION] = session
    end

    def self.get_current_session
      Thread.current[THREAD_SESSION]
    end

    def initialize
      @session_counts = {}
      @mutex = Mutex.new
      @track_sessions = false
    end

    def create_session
      return unless @track_sessions
      start_time = Time.now().utc().strftime('%Y-%m-%dT%H:%M:00')
      new_session = {
        :id => SecureRandom.uuid,
        :startedAt => start_time,
        :events => {
          :handled => 0,
          :unhandled => 0
        }
      }
      SessionTracker.set_current_session(new_session)
      add_session(start_time)
    end

    def send_sessions
      return unless @track_sessions
      @mutex.lock
      begin
        sessions = []
        @session_counts.each do |min, count|
          sessions << {
            :startedAt => min,
            :sessionsStarted => count
          }
        end
        @session_counts = {}
      ensure
        @mutex.unlock
      end
      deliver(sessions)
    end

    def start_delivery_thread
      @track_sessions = true
      @initialised_sessions = false unless defined?(@initialised_sessions)
      if !@initialised_sessions
        @initialised_sessions = true
        at_exit do
          if !@delivery_thread.nil? && @delivery_thread.status == 'sleep'
            @delivery_thread.terminate
            send_sessions
          else
            @delivery_thread.join
          end
        end
        @delivery_thread = Thread.new do
          while true
            sleep(30)
            if @session_counts.size > 0
              send_sessions
            end
          end
        end
      end
    end

    private
    def add_session(min)
      @mutex.lock
      begin
        @session_counts[min] ||= 0
        @session_counts[min] += 1
      ensure
        @mutex.unlock
      end
    end

    def deliver(sessionCounts)
      config = Bugsnag.configuration
      if sessionCounts.length == 0
        config.debug("No sessions to deliver")
        return
      end

      if !Bugsnag.configuration.valid_api_key?
        config.debug("Not delivering sessions due to an invalid api_key")
        return
      end

      if !config.should_notify_release_stage?
        config.debug("Not delivering sessions due to notify_release_stages :#{@config.notify_release_stages.inspect}")
        return
      end

      body = {
        :notifier => {
          :name => Bugsnag::Report::NOTIFIER_NAME,
          :url => Bugsnag::Report::NOTIFIER_URL,
          :version => Bugsnag::Report::NOTIFIER_VERSION
        },
        :device => {
          :hostname => config.hostname
        },
        :app => {
          :version => config.app_version,
          :releaseStage => config.release_stage,
          :type => config.app_type
        },
        :sessionCounts => sessionCounts
      }
      payload = ::JSON.dump(body)

      headers = {
        "Bugsnag-Api-Key" => config.api_key,
        "Bugsnag-Payload-Version" => SESSION_PAYLOAD_VERSION
      }

      options = {:headers => headers, :success => '202'}
      Bugsnag::Delivery[config.delivery_method].deliver(config.session_endpoint, payload, config, options)
    end
  end
end