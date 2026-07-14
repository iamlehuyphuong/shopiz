# OmniAuth configuration
# Sets the full host URL for callbacks and proper redirect handling
OmniAuth.config.full_host = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
OmniAuth.config.path_prefix = '/auth'

GOOGLE_OAUTH_SETUP_PROC = proc do |env|
  env['omniauth.strategy'].options[:client_id] = GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', ENV.fetch('GOOGLE_OAUTH_CLIENT_ID', ''))
  env['omniauth.strategy'].options[:client_secret] = GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_SECRET', ENV.fetch('GOOGLE_OAUTH_CLIENT_SECRET', ''))
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV.fetch('GOOGLE_OAUTH_CLIENT_ID', ''), ENV.fetch('GOOGLE_OAUTH_CLIENT_SECRET', ''), {
    provider_ignores_state: true,
    setup: GOOGLE_OAUTH_SETUP_PROC
  }
end
