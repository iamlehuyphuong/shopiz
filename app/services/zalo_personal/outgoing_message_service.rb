class ZaloPersonal::OutgoingMessageService < ZaloPersonal::BaseService
  pattr_initialize [:inbox!, :params!]

  private

  def message_type
    @message_type ||= :outgoing
  end

  def zalo_user?
    get_user_info.present?
  end

  def target_user
    params[:data][:idTo]
  end
end
