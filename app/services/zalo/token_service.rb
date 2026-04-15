# Manages Zalo OA access token lifecycle with Redis-based distributed locking
# Uses Redis::LockManager to prevent race conditions when multiple processes refresh tokens
class Zalo::TokenService
  pattr_initialize [:channel!]

  # Returns a valid access token, refreshing if necessary
  def access_token
    return current_access_token if token_valid?

    refresh!
  end

  # Forces token refresh with distributed lock
  def refresh!
    lock_manager = Redis::LockManager.new
    begin
      unless lock_manager.lock(lock_key, 30.seconds)
        # Another process is refreshing, wait and return current token
        channel.reload
        return current_access_token
      end

      result = attempt_refresh
      if result['access_token']
        channel.update!(
          oa_access_token: result['access_token'],
          refresh_token: result['refresh_token'],
          expires_in: result['expires_in']
        )
        lock_manager.unlock(lock_key)
        result['access_token']
      else
        lock_manager.unlock(lock_key)
        channel.prompt_reauthorization! unless channel.reauthorization_required?
        current_access_token
      end
    rescue StandardError => e
      lock_manager.unlock(lock_key)
      raise e
    end
  end

  private

  def current_access_token
    channel.oa_access_token
  end

  def token_valid?
    # expires_in is in seconds from the time it was issued
    # We consider token valid if it has more than 5 minutes remaining
    return false if channel.expires_in.blank?

    token_expiry = channel.updated_at + channel.expires_in.seconds
    5.minutes.from_now < token_expiry
  end

  def lock_key
    format(Redis::Alfred::ZALO_OA_REFRESH_TOKEN_MUTEX, channel_id: channel.id)
  end

  def attempt_refresh
    HTTParty.post(
      'https://oauth.zaloapp.com/v4/oa/access_token',
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded',
        'secret_key' => GlobalConfigService.load('ZALO_OA_APP_SECRET', '')
      },
      body: {
        refresh_token: channel.refresh_token,
        app_id: GlobalConfigService.load('ZALO_OA_APP_ID', ''),
        grant_type: 'refresh_token'
      }
    )
  end
end
