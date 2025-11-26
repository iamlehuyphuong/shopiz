Polar.configure do |config|
  config.access_token = ENV['POLAR_ACCESS_TOKEN']
  config.sandbox = ENV['POLAR_ENV'] == 'sandbox'
end
