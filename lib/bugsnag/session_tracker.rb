require 'thread'
require 'time'
require 'securerandom'

module Bugsnag
  class SessionTracker

    THREAD_SESSION = "bugsnag_session"
    TIME_THRESHOLD = 60
    FALLBACK_TIME = 300
    MAXIMUM_SESSION_COUNT = 50
    SESSION_PAYLOAD_VERSION = "1.0"

    attr_reader :session_counts
    attr_writer :config

    def self.set_current_session(session)
      Thread.current[THREAD_SESSION] = session
    end

    def self.get_current_session
      Thread.current[THREAD_SESSION]
    end

    def initialize(configuration)
      @session_counts = {}
      @config = configuration
      @mutex = Mutex.new
      @last_sent = Time.now
    end

    def create_session
      return unless @config.track_sessions
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
      add_thread = Thread.new { add_session(start_time) }
      add_thread.join()
    end

    def send_sessions
      @mutex.lock
      begin
        deliver_sessions
      ensure
        @mutex.unlock
      end
    end

    private
    def add_session(min)
      @mutex.lock
      begin
        @registered_at_exit = false unless defined?(@registered_at_exit)
        if !@registered_at_exit
          @registered_at_exit = true
          at_exit do
            @deliver_fallback.terminate
            deliver_sessions
          end
        end
        @session_counts[min] ||= 0
        @session_counts[min] += 1
        if Time.now() - @last_sent > TIME_THRESHOLD
          deliver_sessions
        end
      ensure
        @mutex.unlock
      end
    end

    def deliver_sessions
      return unless @config.track_sessions
      sessions = []
      @session_counts.each do |min, count|
        sessions << {
          :startedAt => min,
          :sessionsStarted => count
        }
        if sessions.size >= MAXIMUM_SESSION_COUNT
          deliver(sessions)
          sessions = []
        end
      end
      @session_counts = {}
      reset_delivery_thread
      deliver(sessions)
    end

    def reset_delivery_thread
      if !@deliver_fallback.nil? && @deliver_fallback.status == 'sleep'
        @deliver_fallback.terminate
      end
      @deliver_fallback = Thread.new do
        sleep(FALLBACK_TIME)
        deliver_sessions
      end
    end

    def deliver(sessionCounts)
      if sessionCounts.length == 0
        @config.debug("No sessions to deliver")
        return
      end
      
      if !@config.valid_api_key?
        @config.debug("Not delivering sessions due to an invalid api_key")
        return
      end
      
      if !@config.should_notify_release_stage?
        @config.debug("Not delivering sessions due to notify_release_stages :#{@config.notify_release_stages.inspect}")
        return
      end

      if @config.delivery_method != :thread_queue
        @config.debug("Not delivering sessions due to asynchronous delivery being disabled")
        return
      end
      
      payload = {
        :notifier => {
          :name => Bugsnag::Report::NOTIFIER_NAME,
          :url => Bugsnag::Report::NOTIFIER_URL,
          :version => Bugsnag::Report::NOTIFIER_VERSION
        },
        :device => {
          :hostname => @config.hostname
        },
        :app => {
          :version => @config.app_version,
          :releaseStage => @config.release_stage,
          :type => @config.app_type
        },
        :sessionCounts => sessionCounts
      }

      headers = {
        :"Bugsnag-Api-Key" => @config.api_key,
        :"Bugsnag-Payload-Version" => SESSION_PAYLOAD_VERSION
      }

      options = {:headers => headers, :backoff => true, :success => '202'}
      @last_sent = Time.now
      Bugsnag::Delivery[@config.delivery_method].deliver(@config.session_endpoint, payload, @config, options)
    end
  end
end