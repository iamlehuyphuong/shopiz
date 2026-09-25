class ZaloPersonal::IncomingMessageService < ZaloPersonal::BaseService
  private

  def message_type
    @message_type ||= :incoming
  end

  def zalo_user?
    if params.key?(:chat_type)
      params[:chat_type].to_i == 0
    else
      !params[:isGroup]
    end
  end

  def target_user
    params[:uidFrom]
  end
end
