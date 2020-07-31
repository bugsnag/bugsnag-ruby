class ShoryukenWorker
  include Shoryuken::Worker

  shoryuken_options queue: 'hello', auto_delete: true

  def perform(_sqs_message, name)
    raise "HELLO #{name.upcase}!!!"
  end
end
