require 'bugsnag'

Rake::TaskManager.record_task_metadata = true

module Bugsnag::Rake
  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      class << self
        alias_method :original_define_task, :define_task
        alias_method :define_task, :bugsnag_define_task
      end
    end

    Bugsnag.before_notify_callbacks << lambda {|notif|
      task = Thread.current[:bugsnag_running_task]
      next unless task

      notif.add_tab(:rake_task, {
        :name => task.name,
        :description => task.full_comment,
        :arguments => task.arg_description
      })

      notif.context ||= task.name
    }
  end

  module ClassMethods
    def bugsnag_define_task(*args, &block)
      task = self.original_define_task(*args) do |*block_args|
        begin
          old_task = Thread.current[:bugsnag_running_task]
          Thread.current[:bugsnag_running_task] = task

          yield(*block_args) if block_given?
        rescue Exception => e
          Bugsnag.auto_notify(e)
          raise
        ensure
          Thread.current[:bugsnag_running_task] = old_task
        end
      end
    end
  end
end

Rake::Task.send(:include, Bugsnag::Rake) if defined?(Rake::Task)
