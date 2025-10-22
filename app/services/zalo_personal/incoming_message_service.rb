class ZaloPersonal::IncomingMessageService < ZaloPersonal::BaseService

  private

  def message_type
    @message_type ||= :incoming
  end

  def zalo_user?
    params[:data][:idTo] == params[:_accountId]
  end

  def target_user
    params[:data][:uidFrom]
  end
end
