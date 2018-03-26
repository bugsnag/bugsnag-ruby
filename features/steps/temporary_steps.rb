Then(/^the event "(.+)" is a parsable timestamp in seconds$/) do |field|
  step "the payload field \"events.0.#{field}\" is a parsable timestamp in seconds"
end
Then(/^the payload field "(.+)" is a parsable timestamp in seconds(?: for request(\d+))?$/) do |field, request_index|
  value = read_key_path(find_request(request_index)[:body], field)
  begin
    int = value.to_i
    parsed_time = Time.at(int)
  rescue => exception
  end
  assert_not_nil(parsed_time)
end
