module Api::V1::InboxesHelper
  def inbox_name(channel)
    return channel.try(:bot_name) if channel.is_a?(Channel::Telegram)

    permitted_params[:name]
  end

  private

  def account_channels_method
    {
      'web_widget' => Current.account.web_widgets,
      'api' => Current.account.api_channels,
      'telegram' => Current.account.telegram_channels,
      'whatsapp' => Current.account.whatsapp_channels
    }[permitted_params[:channel][:type]]
  end

  def validate_limit
    return unless Current.account.inboxes.count >= Current.account.usage_limits[:inboxes]

    render_payment_required(I18n.t('common.over_limit'))
  end
end
