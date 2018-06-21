initiator = ENV['CALLBACK_INITIATOR']

require "./stack_frame_modification/initiators/#{initiator}"

callback = Proc.new do |report|
  report.exceptions[0][:stacktrace].shift
end

run(callback)