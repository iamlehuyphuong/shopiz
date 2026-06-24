class Api::V1::Accounts::Conversations::ZaloGroupMembersController < Api::V1::Accounts::Conversations::BaseController
  def index
    members = ZaloPersonal::GetGroupMembersService.new(@conversation).perform
    render json: members
  end

  def sync
    ZaloPersonal::GetGroupMembersService.new(@conversation).sync!
    members = ZaloPersonal::GetGroupMembersService.new(@conversation).perform
    render json: members
  end
end
