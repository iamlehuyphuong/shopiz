class TiktokShop::CallbackController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def create
    code = params[:code]
    account_id = params[:state]
    frontend_url = ENV.fetch('FRONTEND_URL', nil)

    tiktok_session_id, shop_name = TiktokShop::AuthService.new(account_id, code).perform
    redirect_to "#{frontend_url}/app/accounts/#{account_id}/settings/inboxes/new/tiktok_shop/?tiktok_session_id=#{tiktok_session_id}&shop_name=#{shop_name}"
  end
end
