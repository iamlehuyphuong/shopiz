Polar.configure do |config|
  config.access_token = ENV.fetch('POLAR_ACCESS_TOKEN')
  config.sandbox = ENV['POLAR_ENV'] == 'sandbox'
end
