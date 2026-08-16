class Api::V1::Accounts::Conversations::ZaloGroupMembersController < Api::V1::Accounts::Conversations::BaseController
  def index
    members = group_members_service.perform
    render json: members
  end

  def sync
    group_members_service.sync!
    members = group_members_service.perform
    render json: members
  end

  private

  def group_members_service
    @group_members_service ||= if @conversation.inbox.channel_type == 'Channel::ZaloOa'
                                 Zalo::GetGroupMembersService.new(@conversation)
                               else
                                 ZaloPersonal::GetGroupMembersService.new(@conversation)
                               end
  end
end
