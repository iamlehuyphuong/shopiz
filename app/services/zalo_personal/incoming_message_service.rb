class ZaloPersonal::IncomingMessageService < ZaloPersonal::BaseService

  private

  def message_type
    @message_type ||= :incoming
  end

  def zalo_user?
    !params[:isGroup]
  end

  def target_user
    params[:uidFrom]
  end
end
