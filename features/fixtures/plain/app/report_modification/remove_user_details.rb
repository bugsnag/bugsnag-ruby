initiator = ENV['CALLBACK_INITIATOR']

require "./report_modification/initiators/#{initiator}"

callback = Proc.new do |report|
  report.user = {
    :id => '0001',
    :email => 'test@test.com',
    :name => 'leo testman'
  }
  report.user = nil
end

run(callback)