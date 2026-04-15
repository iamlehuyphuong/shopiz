# == Schema Information
#
# Table name: contact_optins
#
#  id          :bigint           not null, primary key
#  contact_id  :bigint           not null
#  inbox_id    :bigint           not null
#  token       :string           not null
#  topic       :string
#  status      :integer          default("active")
#  expires_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_contact_optins_on_contact_id  (contact_id)
#  index_contact_optins_on_inbox_id    (inbox_id)
#  index_contact_optins_on_token       (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
class ContactOptin < ApplicationRecord
  belongs_to :contact
  belongs_to :inbox

  validates :token, presence: true, uniqueness: true

  enum status: { active: 0, revoked: 1, expired: 2 }
end
