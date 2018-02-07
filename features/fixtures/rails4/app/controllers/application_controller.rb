class ApplicationController < ActionController::Base
  before_bugsnag_notify only: [:rails_before_handled] do |report|
    report.add_tab("before_notify", {source: "rails_before_handled"})
  end

  before_bugsnag_notify only: [:rails_before_unhandled] do |report|
    report.add_tab("before_notify", {source: "rails_before_unhandled"})
  end

  def index
    render json: {}
  end

  def unhandled
    generate_unhandled_error
  end

  def unthrown_handled
    Bugsnag.notify(RuntimeError.new("unthrown handled error"))
    render json: {}
  end

  def thrown_handled
    begin
      generate_unhandled_error
    rescue
      Bugsnag.notify $!
    end
    render json: {}
  end

  def string_notify
    Bugsnag.notify("handled string")
    render json: {}
  end

  def rails_before_handled
    Bugsnag.notify("handled string")
    render json: {}
  end

  def rails_before_unhandled
    generate_unhandled_error
  end

  def set_config_option
    name = params[:name]

    if ["true", "false"].include? params[:value]
      value = params[:value] == "true"
    else
      value = params[:value]
    end

    case name
    when "notify_release_stages", "meta_data_filters", "ignore_classes"
      value = [params[:value]]
    when "ignore_messages"
      value = [lambda {|ex| ex.message == params[:value]}]
    end

    Bugsnag.configuration.public_send(:"#{name}=", value)
    render json: {}
  end

  def disable_auto_notify
    Bugsnag.configuration.auto_notify = false
  end
end
