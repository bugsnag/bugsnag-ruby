endpoint = 'http://localhost:4576'

# this must be a real region for Moto to work
aws_region = ENV.fetch('AWS_REGION', 'us-west-1')
aws_access_key_id = ENV.fetch('AWS_ACCESS_KEY_ID', 'foo')
aws_secret_access_key = ENV.fetch('AWS_SECRET_ACCESS_KEY', 'bar')

Shoryuken.configure_client do |config|
  Rails.logger = Shoryuken::Logging.logger

  config.sqs_client = Aws::SQS::Client.new(
    region: aws_region,
    access_key_id: aws_access_key_id,
    secret_access_key: aws_secret_access_key,
    endpoint: endpoint,
    verify_checksums: false
  )
end

Shoryuken.configure_server do |config|
  Rails.logger = Shoryuken::Logging.logger

  config.sqs_client = Aws::SQS::Client.new(
    region: aws_region,
    access_key_id: aws_access_key_id,
    secret_access_key: aws_secret_access_key,
    endpoint: endpoint,
    verify_checksums: false
  )
end
