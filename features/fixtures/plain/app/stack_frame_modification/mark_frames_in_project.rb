initiator = ENV['CALLBACK_INITIATOR']

require "./stack_frame_modification/initiators/#{initiator}"

callback = Proc.new do |report|
  report.exceptions[0][:stacktrace].each_with_index do |frame, index|
    if index == 0
      frame[:inProject] = nil
    else
      frame[:inProject] = true
    end
  end
end

run(callback)
