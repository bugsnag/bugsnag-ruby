initiator = ENV['CALLBACK_INITIATOR']

require "./report_modification/initiators/#{initiator}"

callback = Proc.new do |report|
  report.user = {
    :type => 'amateur',
    :location => 'testville',
    :details => {
      :a => 'foo',
      :b => 'bar'
    }
  }
end

run(callback)