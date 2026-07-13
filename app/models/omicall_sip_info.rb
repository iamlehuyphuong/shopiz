class OmicallSipInfo < ApplicationRecord
  belongs_to :account
  belongs_to :user

  encrypts :sip_password

  validates :sip_user, presence: true
  validates :sip_domain, presence: true
  validates :user_id, uniqueness: { scope: :account_id }
end
