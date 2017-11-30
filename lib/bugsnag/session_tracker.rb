require 'thread'
require 'time'
require 'securerandom'

module Bugsnag
  class SessionTracker

    THREAD_SESSION = "bugsnag_session"
    TIME_THRESHOLD = 60
    MAXIMUM_SESSION_COUNT = 50
    SESSION_PAYLOAD_VERSION = "1.0"

    attr_reader :delivery_queue
    attr_accessor :user_callback
    attr_writer :config

    def initialize(configuration)
      @config = configuration
      @delivery_queue = Queue.new
      @mutex = Mutex.new
      @last_sent = Time.now
    end

    def create_session(user=nil)
      unless @config.track_sessions
        return
      end
      if user.nil? && (defined?(self.user_callback) === "method")
        user = self.user_callback
      end
      new_session = {
        :id => SecureRandom.uuid,
        :startedAt => Time.now().utc().strftime('%Y-%m-%dT%H:%M:%S')
      }
      session_copy = new_session.clone
      session_copy[:user] = user
      add_thread = Thread.new { queue_session(session_copy) }
      add_thread.join()
      new_session[:events] = {
        :handled => 0,
        :unhandled => 0
      }
      Thread.current[THREAD_SESSION] = new_session
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
    def queue_session(session)
      @mutex.lock
      begin
        @delivery_queue.push(session)
        if Time.now() - @last_sent > TIME_THRESHOLD
          deliver_sessions
        end
      ensure
        @mutex.unlock
      end
    end

    private
    def deliver_sessions
      unless @config.track_sessions
        return
      end
      sessions = []
      while !@delivery_queue.empty?
        sessions << @delivery_queue.pop
      end
      deliver(sessions)
    end

    private
    def deliver(sessions)
      if sessions.length == 0
        configuration.debug("No sessions to deliver")
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
        :sessions => sessions
      }

      headers = {
        :"Bugsnag-Api-Key" => @config.api_key,
        :"Bugsnag-Payload-Version" => SESSION_PAYLOAD_VERSION
      }

      options = {:headers => headers, :backoff => true, :success => '202'}
      Bugsnag::Delivery[@config.delivery_method].deliver(@config.session_endpoint, payload, @config, options)
    end
  end
end