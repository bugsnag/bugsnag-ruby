initiator = ENV['CALLBACK_INITIATOR']

require "./report_modification/initiators/#{initiator}"

callback = Proc.new do |report|
  report.api_key = 'abcdefghijklmnopqrstuvwxyz123456'
end

run(callback)