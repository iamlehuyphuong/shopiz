class HomeController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def index
    @subscription_tiers = SubscriptionTier.where(is_free: false).includes(:subscription_plans).order(:id)
    render layout: 'landing'
  end

  def privacy_policy
    content = File.read(Rails.root.join('app/views/home/privacy-policy.md'))
    @html_content = CommonMarker.render_html(content, :DEFAULT)
    render layout: 'landing'
  end

  def terms_of_service
    content = File.read(Rails.root.join('app/views/home/terms-of-service.md'))
    @html_content = CommonMarker.render_html(content, :DEFAULT)
    render layout: 'landing'
  end
end
