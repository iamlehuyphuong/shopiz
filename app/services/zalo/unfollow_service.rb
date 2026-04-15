# Handles Zalo OA 'unfollow' webhook event
# When a user unfollows the OA, marks their follower status as false
class Zalo::UnfollowService
  pattr_initialize [:inbox!, :params!]

  def perform
    contact_inbox = @inbox.contact_inboxes.find_by(source_id: follower_id)
    return unless contact_inbox

    contact = contact_inbox.contact
    contact.additional_attributes['zalo_is_follower'] = false
    contact.additional_attributes['zalo_unfollowed_at'] = Time.current.iso8601
    contact.save!
  end

  private

  def follower_id
    params[:follower][:id]
  end
end
