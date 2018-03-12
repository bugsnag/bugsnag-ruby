initiator = ENV['CALLBACK_INITIATOR']

require "./report_modification/initiators/#{initiator}"

callback = Proc.new do |report|
  report.add_tab(:additional_metadata, {
    :foo => 'foo',
    :bar => [
      'b',
      'a',
      'r'
    ]
  })
  report.add_tab(:additional_metadata, {
    :bar => 'bar',
    :foobar => {
      :first => 'foo',
      :then => 'bar'
    }
  })
end

run(callback)