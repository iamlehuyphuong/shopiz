class ZaloPersonal::OutgoingMessageService < ZaloPersonal::BaseService
  pattr_initialize [:inbox!, :params!]

  private

  def message_type
    @message_type ||= :outgoing
  end

  def zalo_user?
    if params.key?(:chat_type)
      params[:chat_type].to_i == 0
    else
      !params[:isGroup]
    end
  end

  def target_user
    params[:idTo]
  end
end
