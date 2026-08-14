class ZaloPersonal::OutgoingMessageService < ZaloPersonal::BaseService
  pattr_initialize [:inbox!, :params!]

  private

  def message_type
    @message_type ||= :outgoing
  end

  def zalo_user?
    !params[:isGroup]
  end

  def target_user
    params[:idTo]
  end
end
